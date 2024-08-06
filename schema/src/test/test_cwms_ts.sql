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
--%disabled until new parameter types, intervals, and durations are unhidden
 procedure test_create_ts_parameter_types;

--%test(Test rename time series)
--%disabled until new parameter types, intervals, and durations are unhidden
 procedure test_rename_ts;

--%test(Test rename time series inst to median)
--%throws(-20013)
--%disabled until new parameter types, intervals, and durations are unhidden
 procedure test_rename_ts_inst_to_median;

--%test(create depth velocity time series)
 procedure test_create_depth_velocity;

--%test(test micrograms/l)
 procedure test_conc;

--%test(Incremental precip with non zero duration)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE inc_with_zero_duration;

--%test(Incremental cumulative precip with zero duration)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE cum_with_non_zero_duration;

--%test(regular interval with until changed duration)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE untilchanged_with_regular;

--%test(non-const parameter type with until changed duration)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE untilchanged_with_non_const;

--%test(Variable duration with non instantaneous)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE variable_with_inst;

--%test(Variable duration with const)
--%throws(-20205)
--%disabled until new parameter types, intervals, and durations are unhidden
 PROCEDURE variable_with_const;

--%test(Make sure quality on generated rts/lrts values is 0 (unscreened) and not 5 (missing) [JIRA Issue CWMSVIEW-212])
 procedure quality_on_generated_rts_values__JIRA_CWMSVIEW_212;

--%test(create a time series id with null timezone in location that has a  base location: CWDB-175)
 procedure create_ts_with_null_timezone;

--%test(Test flags p_start_inclusive, p_end_inclusive, p_previous, p_next, and ts with aliases: CWDB-180)
 procedure test_inclusion_options__JIRA_CWDB_180;

--%test(Test STORE_TS can create a versioned time series: CWDB-190)
 procedure test_store_ts_can_create_versioned_time_series__JIRA_CWDB_190;
--%test(Test UNDELETE_TS, CWMS_V_DELETED_TS, and CWMS_LOC.DELETE_LOCATION on location with deleted ts)
 procedure test_undelete_ts;

--%test (Test RETRIEVE_TS for regular time series that has undefined interval offset)
 procedure test_retrieve_ts_with_undefined_interval_offset;

--%test(LRL 1Day at 6am EST stores correctly)
 procedure test_lrl_1day_CWDB_202;

--%test(No silent failure on storing data with wrong offset [Jira issue CWDB-204])
 procedure cwdb_204_silent_failure_on_store_ts_with_unexpected_offset;

--%test (CWDB-134 STORE_TS_MULTI doen't hide individual error messages)
 procedure cwdb_134_test_store_multi_does_not_hide_error_messages;

--%test (CWDB-211 Update TSV DML counters to include streamed DML)
 procedure cwdb_211_update_tsv_dml_counters_to_include_streamed_dml;

--%test (Test TOP_OF_INTERVAL_UTC)
 procedure test_top_of_interval_utc;

--%test (Test GET_REG_TS_TIMES)
 procedure test_get_reg_ts_times_utc;

--%test (Test RETRIEVE_TS_RAW)
procedure test_retrieve_ts_raw;

--%test (Test RETRIEVE_TS_F)
procedure test_retrieve_ts_f;

--%test (Test CWMS_V_TS_ID_ACCESS)
procedure test_cwms_v_ts_id_access;

--%test (CWDB-289 Retrieve TS with session time zone other than UTC)
procedure test_cwdb_289_retrieve_ts_with_session_timezone_not_utc;


test_base_location_id VARCHAR2(32) := 'TestLoc1';
test_withsub_location_id VARCHAR2(32) := test_base_location_id||'-withsub';
test_renamed_base_location_id VARCHAR2(32) := 'RenameTestLoc1';
test_renamed_withsub_location_id VARCHAR2(32) := test_renamed_base_location_id||'-withsub';

procedure setup;
procedure teardown;
end test_cwms_ts;
/
show errors;
/* Formatted on 4/28/2022 2:38:41 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &&cwms_schema..test_cwms_ts
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
        CWMS_TS.DELETE_TS (p_cwms_ts_id, cwms_util.delete_all, p_db_office_id => '&&office_id');
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
                              'Delete Insert',
                              p_office_id   => '&&office_id');
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
                          'Delete Insert',
                          p_office_id => '&&office_id');
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
                          'Delete Insert',
                          p_office_id => '&&office_id');
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
--          test_base_location_id || '.Flow.Ave.Irr.Variable.raw'); until new parameter types, intervals, and durations are unhidden
            test_base_location_id || '.Flow.Ave.0.0.raw');
      cwms_loc.rename_location(
         test_base_location_id,
         test_renamed_base_location_id,
         '&&office_id');
	COMMIT;
--      delete_ts_id (test_renamed_base_location_id || '.Flow.Ave.Irr.Variable.raw'); until new parameter types, intervals, and durations are unhidden
        delete_ts_id (test_renamed_base_location_id || '.Flow.Ave.0.0.raw');
        COMMIT;
        cwms_loc.store_location (p_location_id    => test_renamed_withsub_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        cwms_ts.create_ts (
            '&&office_id',
--            test_renamed_withsub_location_id || '.Flow.Ave.Irr.Variable.raw'); until new parameter types, intervals, and durations are unhidden
          test_renamed_withsub_location_id || '.Flow.Ave.0.0.raw');
        delete_ts_id (
--            test_renamed_withsub_location_id || '.Flow.Ave.Irr.Variable.raw'); until new parameter types, intervals, and durations are unhidden
            test_renamed_withsub_location_id || '.Flow.Ave.0.0.raw');
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
--          := test_base_location_id || '.DepthVelocity.Ave.Irr.Variable.raw'; until new intervals and durations are unhidden
            := test_base_location_id || '.DepthVelocity.Ave.0.0.raw';
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
        l_location_id    VARCHAR2 (57) := test_base_location_id||'_1'; -- prevent deadlock with other tests
        l_ts_id          VARCHAR2 (191) := l_location_id || '.Code.Inst.1Day.0.QualityTest';
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
      SELECT cwms_t_tsv (FROM_TZ (CAST (l_start_time + LEVEL - 1 AS TIMESTAMP), l_time_zone),
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
        cwms_loc.store_location (p_location_id    => l_location_id,
                                 p_time_zone_id   => l_time_zone,
                                 p_active         => 'T',
                                 p_db_office_id   => l_office_id);
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
      cwms_cache.set_dbms_output(cwms_loc.g_location_code_cache, true);
      setup;
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

      cwms_cache.set_dbms_output(cwms_loc.g_location_code_cache, false);
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
    --------------------------------------------------------------------------------
    -- procedure test_retrieve_ts_with_undefined_interval_offset
    --------------------------------------------------------------------------------
    procedure test_retrieve_ts_with_undefined_interval_offset
    is
       l_ts_data sys_refcursor;
       l_rts_id  varchar2(191)  := test_base_location_id||'.Code.Inst.1Hour.0.Test';
       ts_id_not_found     exception;
       item_already_exists exception;
       pragma exception_init(ts_id_not_found,     -20001);
       pragma exception_init(item_already_exists, -20003);
    begin
      teardown;
       begin
          cwms_loc.store_location(
             p_location_id  => test_base_location_id,
             p_db_office_id => '&&office_id');
       exception
          when item_already_exists then null;
       end;
       begin
          cwms_ts.delete_ts(
             p_cwms_ts_id    => l_rts_id,
             p_delete_action => cwms_util.delete_all,
             p_db_office_id  => '&&office_id');
       exception
          when ts_id_not_found then null;
       end;
       declare
          l_debug_output boolean;
       begin
          l_debug_output := cwms_util.output_debug_info;
          cwms_util.set_output_debug_info(true);
          cwms_ts.create_ts(
             p_cwms_ts_id  => l_rts_id,
             p_versioned   => 'F',
             p_active_flag => 'T',
             p_office_id   => '&&office_id');
          cwms_ts.zretrieve_ts(
             p_at_tsv_rc    => l_ts_data,
             p_units        => 'n/a',
             p_cwms_ts_id   => l_rts_id,
             p_start_time   => sysdate - 1,
             p_end_time     => sysdate,
             p_db_office_id => '&&office_id');
          cwms_util.set_output_debug_info(l_debug_output);
       end;
    end test_retrieve_ts_with_undefined_interval_offset;
   --------------------------------------------------------------------------------
   -- procedure cwdb_204_silent_failure_on_store_ts_with_unexpected_offset
   --------------------------------------------------------------------------------
   procedure cwdb_204_silent_failure_on_store_ts_with_unexpected_offset
   is
      l_ts_id      varchar2 (191) := test_base_location_id || '.Code.Inst.1Hour.0.Test';
      l_loc_id      varchar2 (57)  := test_base_location_id;
      l_unit        varchar2 (16)  := 'n/a';
      l_office_id   varchar2 (16)  := '&&office_id';
      l_ts_data     cwms_t_ztsv_array;
   begin
      setup();
      cwms_loc.store_location(
         p_location_id  => l_loc_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      ---------------------------------------------
      -- create_time series with 0-minute offset --
      ---------------------------------------------
      cwms_ts.create_ts(
         l_ts_id,
         0,
         null,
         null,
         'F',
         'T',
         '&&office_id');
      ---------------------------------------------
      -- store time series with 15-minute offset --
      ---------------------------------------------
      l_ts_data := cwms_t_ztsv_array (
         cwms_t_ztsv (date '2021-10-01' + 1 / 24 + 15 / 1440, 1, 0),
         cwms_t_ztsv (date '2021-10-01' + 2 / 24 + 15 / 1440, 2, 0),
         cwms_t_ztsv (date '2021-10-01' + 3 / 24 + 15 / 1440, 3, 0),
         cwms_t_ztsv (date '2021-10-01' + 4 / 24 + 15 / 1440, 4, 0),
         cwms_t_ztsv (date '2021-10-01' + 5 / 24 + 15 / 1440, 5, 0),
         cwms_t_ztsv (date '2021-10-01' + 6 / 24 + 15 / 1440, 6, 0));
      begin
         cwms_ts.zstore_ts (
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => l_office_id);
         cwms_err.raise('ERROR', 'Expected exception not raised.');
      exception
         when others then
            if not regexp_like(
               dbms_utility.format_error_stack,
               '.*Incoming Data Set''s UTC_OFFSET: \d+ does not match its previously stored UTC_OFFSET of: \d+ - data set was NOT stored.*',
               'mn')
            then
               raise;
            end if;
      end;
   end cwdb_204_silent_failure_on_store_ts_with_unexpected_offset;
   --------------------------------------------------------------------------------
   -- procedure cwdb_134_test_store_multi_does_not_hide_error_messages
   --------------------------------------------------------------------------------
   procedure cwdb_134_test_store_multi_does_not_hide_error_messages
   is
      l_ts_id_1        varchar2 (191) := test_base_location_id || '.Code-Test1.Inst.1Hour.0.Test';
      l_ts_id_2        varchar2 (191) := test_base_location_id || '.Code-Test2.Inst.1Hour.0.Test';
      l_loc_id         varchar2 (57)  := test_base_location_id;
      l_unit           varchar2 (16)  := 'n/a';
      l_office_id      varchar2 (16)  := '&&office_id';
      l_ts_data        cwms_t_timeseries_array;
      l_zts_data       cwms_t_ztimeseries_array;
      l_expected_error varchar2(4000) := '^.+1: '
                                         ||l_ts_id_1
                                         ||'.+ERROR: Incoming data set contains multiple interval offsets. Unable to store data for '
                                         ||l_ts_id_1
                                         ||'.+2: '
                                         ||l_ts_id_2
                                         ||'.+ERROR: Incoming data set contains multiple interval offsets. Unable to store data for '
                                         ||l_ts_id_2
                                         ||'.+$';
   begin
      -------------------------------------------------
      -- store the location and create the data sets --
      -------------------------------------------------
      delete_all;
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_db_office_id => l_office_id);
      l_ts_data := cwms_t_timeseries_array();
      l_ts_data.extend(2);
      l_ts_data(1) := cwms_t_timeseries(
         l_ts_id_1,
         l_unit,
         cwms_t_tsv_array());
      l_ts_data(1).data.extend(5);
      l_ts_data(1).data(1) := cwms_t_tsv(from_tz(timestamp '2023-04-13 01:00:00', 'UTC'), 1.0, 3.0);
      l_ts_data(1).data(2) := cwms_t_tsv(from_tz(timestamp '2023-04-13 02:05:00', 'UTC'), 2.0, 3.0);
      l_ts_data(1).data(3) := cwms_t_tsv(from_tz(timestamp '2023-04-13 03:05:00', 'UTC'), 3.0, 3.0);
      l_ts_data(1).data(4) := cwms_t_tsv(from_tz(timestamp '2023-04-13 04:05:00', 'UTC'), 4.0, 3.0);
      l_ts_data(1).data(5) := cwms_t_tsv(from_tz(timestamp '2023-04-13 05:00:00', 'UTC'), 5.0, 3.0);
      l_ts_data(2) := l_ts_data(1);
      l_ts_data(2).tsid := l_ts_id_2;
      l_zts_data := cwms_t_ztimeseries_array();
      l_zts_data.extend(2);
      l_zts_data(1) := cwms_t_ztimeseries(
         l_ts_id_1,
         l_unit,
         cwms_t_ztsv_array());
      l_zts_data(1).data.extend(5);
      l_zts_data(1).data(1) := cwms_t_ztsv(timestamp '2023-04-13 01:00:00', 1.0, 3.0);
      l_zts_data(1).data(2) := cwms_t_ztsv(timestamp '2023-04-13 02:05:00', 2.0, 3.0);
      l_zts_data(1).data(3) := cwms_t_ztsv(timestamp '2023-04-13 03:05:00', 3.0, 3.0);
      l_zts_data(1).data(4) := cwms_t_ztsv(timestamp '2023-04-13 04:05:00', 4.0, 3.0);
      l_zts_data(1).data(5) := cwms_t_ztsv(timestamp '2023-04-13 05:00:00', 5.0, 3.0);
      l_zts_data(2) := l_zts_data(1);
      l_zts_data(2).tsid := l_ts_id_2;
      --------------------------------------------------------------------
      -- store with STORE_TS_MULTI with single version date/lrts option --
      --------------------------------------------------------------------
      begin
         cwms_ts.store_ts_multi(
            p_timeseries_array => l_ts_data,
            p_store_rule       => cwms_util.replace_all,
            p_override_prot    => 'F',
            p_version_date     => null,
            p_office_id        => l_office_id,
            p_create_as_lrts   => null);
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, l_expected_error, 'mn') then
               null;
            else
               raise;
            end if;
      end;
      -----------------------------------------------------------------------
      -- store with STORE_TS_MULTI with multiple version dates/lrts option --
      -----------------------------------------------------------------------
      begin
         cwms_ts.store_ts_multi(
            p_timeseries_array => l_ts_data,
            p_store_rule       => cwms_util.replace_all,
            p_override_prot    => 'F',
            p_version_dates    => null,
            p_office_id        => l_office_id,
            p_create_as_lrts   => null);
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, l_expected_error, 'mn') then
               null;
            else
               raise;
            end if;
      end;
      ---------------------------------------------------------------------
      -- store with ZSTORE_TS_MULTI with single version date/lrts option --
      ---------------------------------------------------------------------
      begin
         cwms_ts.zstore_ts_multi(
            p_timeseries_array => l_zts_data,
            p_store_rule       => cwms_util.replace_all,
            p_override_prot    => 'F',
            p_version_date     => null,
            p_office_id        => l_office_id,
            p_create_as_lrts   => null);
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, l_expected_error, 'mn') then
               null;
            else
               raise;
            end if;
      end;
      -----------------------------------------------------------------------
      -- store with ZSTORE_TS_MULTI with single multiple dates/lrts option --
      -----------------------------------------------------------------------
      begin
         cwms_ts.zstore_ts_multi(
            p_timeseries_array => l_zts_data,
            p_store_rule       => cwms_util.replace_all,
            p_override_prot    => 'F',
            p_version_dates    => null,
            p_office_id        => l_office_id,
            p_create_as_lrts   => null);
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, l_expected_error, 'mn') then
               null;
            else
               raise;
            end if;
      end;
   end cwdb_134_test_store_multi_does_not_hide_error_messages;
    --------------------------------------------------------------------------------
    -- procedure test_undelete_ts
    --------------------------------------------------------------------------------
    procedure test_undelete_ts
    is
      x_cannot_delete_loc_1 exception;
      pragma exception_init(x_cannot_delete_loc_1, -20031);
      l_base_ts_id_1 cwms_v_ts_id.cwms_ts_id%type := test_base_location_id||'.Code.Inst.1Hour.0.Test';
      l_base_ts_id_2 cwms_v_ts_id.cwms_ts_id%type := test_base_location_id||'.Flow.Inst.1Hour.0.Test';
      l_sub_ts_id_1 cwms_v_ts_id.cwms_ts_id%type := test_withsub_location_id||'.Code.Inst.1Hour.0.Test';
      l_sub_ts_id_2 cwms_v_ts_id.cwms_ts_id%type := test_withsub_location_id||'.Flow.Inst.1Hour.0.Test';
      l_unit_1  cwms_v_ts_id.unit_id%type := 'n/a';
      l_unit_2  cwms_v_ts_id.unit_id%type := 'cfs';
      l_unit_3  cwms_v_ts_id.unit_id%type := 'n/a';
      l_unit_4  cwms_v_ts_id.unit_id%type := 'cfs';
      l_ts_data cwms_t_ztsv_array := cwms_t_ztsv_array(
                                        cwms_t_ztsv(timestamp '2023-02-03 01:00:00', 1, 0),
                                        cwms_t_ztsv(timestamp '2023-02-03 02:00:00', 2, 0),
                                        cwms_t_ztsv(timestamp '2023-02-03 03:00:00', 3, 0),
                                        cwms_t_ztsv(timestamp '2023-02-03 04:00:00', 4, 0),
                                        cwms_t_ztsv(timestamp '2023-02-03 05:00:00', 5, 0));
      function count_in(p_view_name in varchar2, p_ts_id in varchar2) return pls_integer is
         l_count pls_integer;
      begin
         execute immediate replace('select count(*) from $v where cwms_ts_id = :1', '$v', p_view_name)
            into l_count
           using p_ts_id;
         return l_count;
      end count_in;
    begin
      teardown;
      ---------------------
      -- store locations --
      ---------------------
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      cwms_loc.store_location(
         p_location_id  => test_withsub_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      --------------------------------------------------------------
      -- store time series and verify inclusion in expected views --
      --------------------------------------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_base_ts_id_1,
         p_units           => l_unit_1,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_base_ts_id_2,
         p_units           => l_unit_2,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_sub_ts_id_1,
         p_units           => l_unit_3,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_sub_ts_id_2,
         p_units           => l_unit_4,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
      -------------------------------------------------------------------
      -- delete one time series and verify inclusion in expected views --
      -------------------------------------------------------------------
      cwms_ts.delete_ts(l_sub_ts_id_1, cwms_util.delete_key, '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
      -----------------------------------------------------------------------------------
      -- verify we cant't delete the location key while non-deleted time series remain --
      -----------------------------------------------------------------------------------
      begin
         cwms_loc.delete_location(test_withsub_location_id, cwms_util.delete_key, '&&office_id');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when x_cannot_delete_loc_1 then null;
      end;
      -----------------------------------------------------------------------
      -- delete another time series and verify inclusion in expected views --
      -----------------------------------------------------------------------
      cwms_ts.delete_ts(l_sub_ts_id_2, cwms_util.delete_key, '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(1);
      ----------------------------------------------------------------------
      -- undelete both time series and verify inclusion in expected views --
      ----------------------------------------------------------------------
      cwms_ts.undelete_ts(l_sub_ts_id_1, '&&office_id');
      cwms_ts.undelete_ts(l_sub_ts_id_2, '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
      --------------------------------------------------------------------------------
      -- verify that deleting location key removes deleted time series for location --
      --------------------------------------------------------------------------------
      cwms_ts.delete_ts(l_sub_ts_id_1, cwms_util.delete_key, '&&office_id');
      cwms_ts.delete_ts(l_sub_ts_id_2, cwms_util.delete_key, '&&office_id');
      cwms_loc.delete_location(test_withsub_location_id, cwms_util.delete_key, '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
      ----------------
      -- start over --
      ----------------
      teardown;
      ---------------------
      -- store locations --
      ---------------------
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      cwms_loc.store_location(
         p_location_id  => test_withsub_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      --------------------------------------------------------------
      -- store time series and verify inclusion in expected views --
      --------------------------------------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_base_ts_id_1,
         p_units           => l_unit_1,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_base_ts_id_2,
         p_units           => l_unit_2,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_sub_ts_id_1,
         p_units           => l_unit_3,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_sub_ts_id_2,
         p_units           => l_unit_4,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(1);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(1);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
      ----------------------------------------------------------------------------------------------
      -- verify deleting base location key removes deleted time series for base and sub-locations --
      ----------------------------------------------------------------------------------------------
      cwms_ts.delete_ts(l_base_ts_id_1, cwms_util.delete_key, '&&office_id');
      cwms_ts.delete_ts(l_base_ts_id_2, cwms_util.delete_key, '&&office_id');
      cwms_ts.delete_ts(l_sub_ts_id_1, cwms_util.delete_key, '&&office_id');
      cwms_ts.delete_ts(l_sub_ts_id_2, cwms_util.delete_key, '&&office_id');
      cwms_loc.delete_location(test_base_location_id, cwms_util.delete_key, '&&office_id');
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_ts_id', l_sub_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_base_ts_id_2)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_1)).to_equal(0);
      ut.expect(count_in('cwms_v_deleted_ts_id', l_sub_ts_id_2)).to_equal(0);
    end test_undelete_ts;

   --------------------------------------------------------------------------------
   -- procedure cwdb_211_update_tsv_dml_counters_to_include_streamed_dml
   --------------------------------------------------------------------------------
   procedure cwdb_211_update_tsv_dml_counters_to_include_streamed_dml
   is
      l_ts_id     cwms_v_ts_id.cwms_ts_id%type;
      l_ts_code   cwms_v_ts_id.ts_code%type;
      l_unit      cwms_v_ts_id.unit_id%type := 'n/a';
      l_seconds   number;
      l_time      timestamp;
      l_inserts   pls_integer := 0;
      l_updates   pls_integer := 0;
      l_deletes   pls_integer := 0;
      l_s_inserts pls_integer := 0;
      l_s_updates pls_integer := 0;
      l_s_deletes pls_integer := 0;
      l_rec       at_tsv_count%rowtype;
      l_ts_data   cwms_t_ztsv_array := cwms_t_ztsv_array(
                     cwms_t_ztsv(timestamp '2023-02-03 01:00:00',  1, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 02:00:00',  2, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 03:00:00',  3, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 04:00:00',  4, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 05:00:00',  5, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 06:00:00',  6, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 07:00:00',  7, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 08:00:00',  8, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 09:00:00',  9, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 00:00:00',  0, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 11:00:00', 11, 0),
                     cwms_t_ztsv(timestamp '2023-02-03 12:00:00', 12, 0));
   begin
      -----------
      -- setup --
      -----------
      teardown;
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      cwms_loc.store_location(
         p_location_id  => test_withsub_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      cwms_tsv.is_stream_session := true;
      -----------------------------------
      -- wait until top of next minute --
      -----------------------------------
      dbms_session.sleep(60 - extract(second from systimestamp));
      l_time := trunc(systimestamp, 'MI') + interval '000 00:01:00' day to second;
      for test_streaming in 0..1 loop
         cwms_tsv.is_stream_session := test_streaming = 1; -- normally set from username at init of cwms_tsv package
         -----------------------
         -- store some values --
         -----------------------
         if cwms_tsv.is_stream_session then
            l_ts_id := test_withsub_location_id||'.Code.Inst.1Hour.0.Test';
         else
            l_ts_id := test_base_location_id||'.Code.Inst.1Hour.0.Test';
         end if;
         cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_version_date    => cwms_util.non_versioned,
            p_office_id       => '&&office_id');
         if cwms_tsv.is_stream_session then
            l_s_inserts := l_ts_data.count;
         else
            l_inserts := l_ts_data.count;
         end if;
         l_ts_code := cwms_ts.get_ts_code(l_ts_id, '&&office_id');
         ------------------------
         -- update some values --
         ------------------------
         for i in 1..l_ts_data.count loop
            continue when mod(i, 2) != 0;
            update at_tsv_2023
               set value = value * 10
             where ts_code = l_ts_code
               and date_time = l_ts_data(i).date_time
               and version_date = cwms_util.non_versioned;

            if cwms_tsv.is_stream_session then
               l_s_updates := l_s_updates + 1;
            else
               l_updates := l_updates + 1;
            end if;
         end loop;
         ------------------------
         -- delete some values --
         ------------------------
         for i in 1..l_ts_data.count loop
            continue when mod(i, 3) != 0;
            delete
              from at_tsv_2023
             where ts_code = l_ts_code
               and date_time = l_ts_data(i).date_time
               and version_date = cwms_util.non_versioned;

            if cwms_tsv.is_stream_session then
               l_s_deletes := l_s_deletes + 1;
            else
               l_deletes := l_deletes + 1;
            end if;
         end loop;
         -----------------------
         -- verify the counts --
         -----------------------
         commit;
         cwms_tsv.flush;

         select *
           into l_rec
           from at_tsv_count
          where data_entry_date = l_time;

         ut.expect(l_rec.inserts).to_equal(l_inserts);
         ut.expect(l_rec.updates).to_equal(l_updates);
         ut.expect(l_rec.deletes).to_equal(l_deletes);
         ut.expect(l_rec.s_inserts).to_equal(l_s_inserts);
         ut.expect(l_rec.s_updates).to_equal(l_s_updates);
         ut.expect(l_rec.s_deletes).to_equal(l_s_deletes);
      end loop;
   end cwdb_211_update_tsv_dml_counters_to_include_streamed_dml;
   --------------------------------------------------------------------------------
   -- procedure procedure test_top_of_interval_utc
   --------------------------------------------------------------------------------
   procedure test_top_of_interval_utc
   is
      l_date_fmt varchar2(18) := 'yyyy-mm-dd hh24:mi';
      l_utc_time date := to_date('2020-01-01 00:01', l_date_fmt);
      -----------------------------------------------------------------------------------------
      -- the tests were generated by a python script which brute-forces the expected results --
      -- the script is in this directory as test_cwms_ts.test_top_of_interval_utc.py         --
      -----------------------------------------------------------------------------------------
   begin
      -----------------------------------------------
      -- test previous interval, interval tz = UTC --
      -----------------------------------------------
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'UTC', 'F')).to_equal(to_date('2020-01-01 00:01', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'UTC', 'F')).to_equal(to_date('2019-12-31 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'UTC', 'F')).to_equal(to_date('2019-12-30 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'UTC', 'F')).to_equal(to_date('2019-12-30 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'UTC', 'F')).to_equal(to_date('2019-12-28 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'UTC', 'F')).to_equal(to_date('2019-12-26 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'UTC', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      -------------------------------------------
      -- test next interval, interval tz = UTC --
      -------------------------------------------
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'UTC', 'T')).to_equal(to_date('2020-01-01 00:01', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:02', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:03', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:04', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:05', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:06', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'UTC', 'T')).to_equal(to_date('2020-01-01 00:08', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'UTC', 'T')).to_equal(to_date('2020-01-01 00:10', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'UTC', 'T')).to_equal(to_date('2020-01-01 00:12', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'UTC', 'T')).to_equal(to_date('2020-01-01 00:15', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'UTC', 'T')).to_equal(to_date('2020-01-01 00:20', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'UTC', 'T')).to_equal(to_date('2020-01-01 00:30', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'UTC', 'T')).to_equal(to_date('2020-01-01 01:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'UTC', 'T')).to_equal(to_date('2020-01-01 02:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'UTC', 'T')).to_equal(to_date('2020-01-01 03:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'UTC', 'T')).to_equal(to_date('2020-01-01 04:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'UTC', 'T')).to_equal(to_date('2020-01-01 06:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'UTC', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'UTC', 'T')).to_equal(to_date('2020-01-01 12:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'UTC', 'T')).to_equal(to_date('2020-01-02 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'UTC', 'T')).to_equal(to_date('2020-01-03 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'UTC', 'T')).to_equal(to_date('2020-01-03 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'UTC', 'T')).to_equal(to_date('2020-01-03 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'UTC', 'T')).to_equal(to_date('2020-01-04 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'UTC', 'T')).to_equal(to_date('2020-01-03 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'UTC', 'T')).to_equal(to_date('2020-01-02 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'UTC', 'T')).to_equal(to_date('2020-02-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'UTC', 'T')).to_equal(to_date('2021-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'UTC', 'T')).to_equal(to_date('2030-01-01 00:00', l_date_fmt));
      ------------------------------------------------------
      -- test previous interval, interval tz = US/Pacific --
      ------------------------------------------------------
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:01', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'US/Pacific', 'F')).to_equal(to_date('2019-12-31 23:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'US/Pacific', 'F')).to_equal(to_date('2019-12-31 20:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'US/Pacific', 'F')).to_equal(to_date('2020-01-01 00:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'US/Pacific', 'F')).to_equal(to_date('2019-12-31 20:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'US/Pacific', 'F')).to_equal(to_date('2019-12-31 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'US/Pacific', 'F')).to_equal(to_date('2019-12-30 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'US/Pacific', 'F')).to_equal(to_date('2019-12-31 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'US/Pacific', 'F')).to_equal(to_date('2019-12-30 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'US/Pacific', 'F')).to_equal(to_date('2019-12-30 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'US/Pacific', 'F')).to_equal(to_date('2019-12-28 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'US/Pacific', 'F')).to_equal(to_date('2019-12-26 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'US/Pacific', 'F')).to_equal(to_date('2019-12-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'US/Pacific', 'F')).to_equal(to_date('2019-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'US/Pacific', 'F')).to_equal(to_date('2010-01-01 08:00', l_date_fmt));
      --------------------------------------------------
      -- test next interval, interval tz = US/Pacific --
      --------------------------------------------------
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:01', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:02', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:03', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:04', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:05', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:06', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:08', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:10', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:12', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:15', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:20', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'US/Pacific', 'T')).to_equal(to_date('2020-01-01 00:30', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'US/Pacific', 'T')).to_equal(to_date('2020-01-01 01:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 02:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 02:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 04:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 02:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'US/Pacific', 'T')).to_equal(to_date('2020-01-03 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'US/Pacific', 'T')).to_equal(to_date('2020-01-03 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'US/Pacific', 'T')).to_equal(to_date('2020-01-04 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'US/Pacific', 'T')).to_equal(to_date('2020-01-03 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'US/Pacific', 'T')).to_equal(to_date('2020-01-02 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));
      ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'US/Pacific', 'T')).to_equal(to_date('2020-01-01 08:00', l_date_fmt));

   end test_top_of_interval_utc;
   --------------------------------------------------------------------------------
   -- procedure procedure test_get_reg_ts_times_utc
   --------------------------------------------------------------------------------
   procedure test_get_reg_ts_times_utc
   is
      l_expected_times_1hour_spring_utc   date_table_type;
      l_expected_times_1hour_spring_local date_table_type;
      l_expected_times_1hour_fall_utc     date_table_type;
      l_expected_times_1hour_fall_local   date_table_type;
      l_expected_times_1day_spring_utc    date_table_type;
      l_expected_times_1day_spring_local  date_table_type;
      l_expected_times_1day_fall_utc      date_table_type;
      l_expected_times_1day_fall_local    date_table_type;
      l_reg_times                          date_table_type;
      l_time_window                        date_range_t;
      l_time_zone                          varchar2(28) := 'US/Pacific';
      l_offset                             varchar2(16);
   begin
      l_expected_times_1hour_spring_utc := date_table_type(
         timestamp '2023-03-12 07:15:00',
         timestamp '2023-03-12 08:15:00',
         timestamp '2023-03-12 09:15:00',
         timestamp '2023-03-12 10:15:00',
         timestamp '2023-03-12 11:15:00',
         timestamp '2023-03-12 12:15:00');
      l_expected_times_1hour_spring_local := date_table_type(
         timestamp '2023-03-11 23:15:00',
         timestamp '2023-03-12 00:15:00',
         timestamp '2023-03-12 01:15:00',
         timestamp '2023-03-12 03:15:00',
         timestamp '2023-03-12 04:15:00',
         timestamp '2023-03-12 05:15:00');
      l_expected_times_1hour_fall_utc := date_table_type(
         timestamp '2023-11-05 07:15:00',
         timestamp '2023-11-05 08:15:00',
         timestamp '2023-11-05 09:15:00',
         timestamp '2023-11-05 10:15:00',
         timestamp '2023-11-05 11:15:00',
         timestamp '2023-11-05 12:15:00');
      l_expected_times_1hour_fall_local := date_table_type(
         timestamp '2023-11-05 00:15:00',
         timestamp '2023-11-05 01:15:00',
         timestamp '2023-11-05 02:15:00',
         timestamp '2023-11-05 03:15:00',
         timestamp '2023-11-05 04:15:00');

      l_expected_times_1day_spring_utc := date_table_type(
         timestamp '2023-03-09 12:00:00',
         timestamp '2023-03-10 12:00:00',
         timestamp '2023-03-11 12:00:00',
         timestamp '2023-03-12 12:00:00',
         timestamp '2023-03-13 12:00:00',
         timestamp '2023-03-14 12:00:00');
      l_expected_times_1day_spring_local := date_table_type(
         timestamp '2023-03-09 12:00:00',
         timestamp '2023-03-10 12:00:00',
         timestamp '2023-03-11 12:00:00',
         timestamp '2023-03-12 12:00:00',
         timestamp '2023-03-13 12:00:00',
         timestamp '2023-03-14 12:00:00');
      l_expected_times_1day_fall_utc := date_table_type(
         timestamp '2023-03-09 12:00:00',
         timestamp '2023-03-10 12:00:00',
         timestamp '2023-03-11 12:00:00',
         timestamp '2023-03-12 12:00:00',
         timestamp '2023-03-13 12:00:00',
         timestamp '2023-03-14 12:00:00');
      l_expected_times_1day_fall_local := date_table_type(
         timestamp '2023-11-02 12:00:00',
         timestamp '2023-11-03 12:00:00',
         timestamp '2023-11-04 12:00:00',
         timestamp '2023-11-05 12:00:00',
         timestamp '2023-11-06 12:00:00',
         timestamp '2023-11-07 12:00:00');
      -----------------------------------------------
      -- 1Hour interval across Spring DST boundary --
      -----------------------------------------------
      l_offset := '15';
      l_time_window := date_range_t(
         trunc(l_expected_times_1hour_spring_utc(1), 'HH'),
         trunc(l_expected_times_1hour_spring_utc(l_expected_times_1hour_spring_utc.count), 'HH') + cwms_ts.interval_offset_minutes(l_offset) / 1440);
      ---------------
      -- UTC times --
      ---------------
      dbms_output.put_line('==> 1HOUR SPRING UTC');
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Hour',
         p_offset             => l_offset,
         p_interval_time_zone => 'UTC');
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1hour_spring_utc.count);
      if l_reg_times.count = l_expected_times_1hour_spring_utc.count then
         for i in 1..l_reg_times.count loop
            ut.expect(l_reg_times(i)).to_equal(l_expected_times_1hour_spring_utc(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      -----------------
      -- local times --
      -----------------
      dbms_output.put_line('==> 1HOUR SPRING '||upper(l_time_zone));
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Hour',
         p_offset             => l_offset,
         p_interval_time_zone => l_time_zone);
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1hour_spring_local.count);
      if l_reg_times.count = l_expected_times_1hour_spring_local.count then
         for i in 1..l_reg_times.count loop
            ut.expect(cwms_util.change_timezone(l_reg_times(i), 'UTC', l_time_zone)).to_equal(l_expected_times_1hour_spring_local(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      ---------------------------------------------
      -- 1Hour interval across Fall DST boundary --
      ---------------------------------------------
      l_time_window := date_range_t(
         trunc(l_expected_times_1hour_fall_utc(1), 'HH'),
         trunc(l_expected_times_1hour_fall_utc(l_expected_times_1hour_fall_utc.count), 'HH') + cwms_ts.interval_offset_minutes(l_offset) / 1440);
      ---------------
      -- UTC times --
      ---------------
      dbms_output.put_line('==> 1HOUR FALL UTC');
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Hour',
         p_offset             => l_offset,
         p_interval_time_zone => 'UTC');
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1hour_fall_utc.count);
      if l_reg_times.count = l_expected_times_1hour_fall_utc.count then
         for i in 1..l_reg_times.count loop
            ut.expect(l_reg_times(i)).to_equal(l_expected_times_1hour_fall_utc(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      -----------------
      -- local times --
      -----------------
      dbms_output.put_line('==> 1HOUR FALL '||upper(l_time_zone));
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Hour',
         p_offset             => l_offset,
         p_interval_time_zone => l_time_zone);
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1hour_fall_local.count);
      if l_reg_times.count = l_expected_times_1hour_fall_local.count then
         for i in 1..l_reg_times.count loop
            ut.expect(cwms_util.change_timezone(l_reg_times(i), 'UTC', l_time_zone)).to_equal(l_expected_times_1hour_fall_local(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      ----------------------------------------------
      -- 1Day interval across Spring DST boundary --
      ----------------------------------------------
      ---------------
      -- UTC times --
      ---------------
      l_offset := '12Hours';
      l_time_window := date_range_t(
         trunc(l_expected_times_1day_spring_utc(1), 'DD'),
         trunc(l_expected_times_1day_spring_utc(l_expected_times_1day_spring_utc.count), 'DD') + cwms_ts.interval_offset_minutes(l_offset) / 1440,
         'UTC');
      dbms_output.put_line('==> 1DAY SPRING UTC');
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Day',
         p_offset             => l_offset,
         p_interval_time_zone => 'UTC');
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1day_spring_utc.count);
      if l_reg_times.count = l_expected_times_1day_spring_utc.count then
         for i in 1..l_reg_times.count loop
            ut.expect(l_reg_times(i)).to_equal(l_expected_times_1day_spring_utc(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      -----------------
      -- local times --
      -----------------
      l_time_window := date_range_t(
         trunc(l_expected_times_1day_spring_local(1), 'DD'),
         trunc(l_expected_times_1day_spring_local(l_expected_times_1day_spring_local.count), 'DD') + cwms_ts.interval_offset_minutes(l_offset) / 1440,
         l_time_zone);
      dbms_output.put_line('==> 1DAY SPRING '||upper(l_time_zone));
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Day',
         p_offset             => l_offset,
         p_interval_time_zone => l_time_zone);
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1day_spring_local.count);
      if l_reg_times.count = l_expected_times_1day_spring_local.count then
         for i in 1..l_reg_times.count loop
            ut.expect(cwms_util.change_timezone(l_reg_times(i), 'UTC', l_time_zone)).to_equal(l_expected_times_1day_spring_local(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      --------------------------------------------
      -- 1Day interval across Fall DST boundary --
      --------------------------------------------
      ---------------
      -- UTC times --
      ---------------
      l_time_window := date_range_t(
         trunc(l_expected_times_1day_fall_utc(1), 'DD'),
         trunc(l_expected_times_1day_fall_utc(l_expected_times_1day_fall_utc.count), 'DD') + cwms_ts.interval_offset_minutes(l_offset) / 1440,
         'UTC');
      dbms_output.put_line('==> 1DAY FALL UTC');
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Day',
         p_offset             => l_offset,
         p_interval_time_zone => 'UTC');
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1day_fall_utc.count);
      if l_reg_times.count = l_expected_times_1day_fall_utc.count then
         for i in 1..l_reg_times.count loop
            ut.expect(l_reg_times(i)).to_equal(l_expected_times_1day_fall_utc(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
      -----------------
      -- local times --
      -----------------
      l_time_window := date_range_t(
         trunc(l_expected_times_1day_fall_local(1), 'DD'),
         trunc(l_expected_times_1day_fall_local(l_expected_times_1day_fall_local.count), 'DD') + cwms_ts.interval_offset_minutes(l_offset) / 1440,
         l_time_zone);
      dbms_output.put_line('==> 1DAY FALL '||upper(l_time_zone));
      l_reg_times := cwms_ts.get_reg_ts_times_utc_f(
         p_date_range         => l_time_window,
         p_interval           => '1Day',
         p_offset             => l_offset,
         p_interval_time_zone => l_time_zone);
      ut.expect(l_reg_times.count).to_equal(l_expected_times_1day_fall_local.count);
      if l_reg_times.count = l_expected_times_1day_fall_local.count then
         for i in 1..l_reg_times.count loop
            ut.expect(cwms_util.change_timezone(l_reg_times(i), 'UTC', l_time_zone)).to_equal(l_expected_times_1day_fall_local(i));
         end loop;
      else
         dbms_output.put_line(l_time_window.start_time('UTC')||' - '||l_time_window.end_time('UTC'));
         for i in 1..l_reg_times.count loop
            dbms_output.put_line(i||chr(9)||l_reg_times(i));
         end loop;
      end if;
   end test_get_reg_ts_times_utc;
   --------------------------------------------------------------------------------
   -- procedure procedure test_retrieve_ts_raw
   --------------------------------------------------------------------------------
   procedure test_retrieve_ts_raw
   is
      type ztsv_array_tab is table of cwms_t_ztsv_array;
      l_ts_data_in    ztsv_array_tab;
      l_version_dates cwms_t_date_table;
      l_ts_data_out   cwms_t_ztsv_array;
      l_ts_id         cwms_v_ts_id.cwms_ts_id%type := test_base_location_id||'.Code.Inst.1Hour.0.Test';
      l_unit_id       cwms_v_ts_id.unit_id%type := 'n/a';
   begin
      setup;
--      dbms_output.enable;
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      l_version_dates := cwms_t_date_table(cwms_util.non_versioned, date '2024-02-02', date '2024-02-03');
      l_ts_data_in := ztsv_array_tab(null, null, null);
      for i in 1..3 loop
         l_ts_data_in(i) := cwms_t_ztsv_array();
         for j in 0..24 loop
            continue when mod(j, 3) = 0 or mod(j, 5) = 0;
            l_ts_data_in(i).extend;
            l_ts_data_in(i)(l_ts_data_in(i).count) := cwms_t_ztsv(date '2024-02-01' + j / 24, j + i - 1, 0);
         end loop;

         if i = 2 then
            cwms_ts.set_tsid_versioned(l_ts_id, 'T', '&&office_id');
         end if;

         dbms_output.put_line('Storing data with version date = '||to_char(l_version_dates(i), 'yyyy-mm-dd hh24:mi:ss'));
         cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit_id,
            p_timeseries_data => l_ts_data_in(i),
            p_store_rule      => cwms_util.replace_all,
            p_version_date    => l_version_dates(i),
            p_office_id       => '&&office_id');
         commit;
      end loop;

      for i in 1..4 loop
         dbms_output.put_line('==> i = '||i);
         dbms_output.put_line('==> version_date = '||case i when 1 then 'null' when 4 then 'null' else to_char(l_version_dates(i), 'yyyy-mm-dd hh:mi:ss') end);
         dbms_output.put_line('==> max_version = '||case when i = 4 then 'F' else 'T' end);
         cwms_ts.retrieve_ts_raw(
            p_ts_retrieved => l_ts_data_out,
            p_ts_code      => cwms_ts.get_ts_code(l_ts_id, '&&office_id'),
            p_date_range   => cwms_t_date_range(l_ts_data_in(1)(1).date_time, l_ts_data_in(1)(l_ts_data_in(1).count).date_time, 'UTC'),
            p_version_date => case i when 1 then null when 4 then null else l_version_dates(i) end,
            p_max_version  => case when i = 4 then 'F' else 'T' end);
         dbms_output.put_line('==> values returned = '||l_ts_data_out.count);

         ut.expect(l_ts_data_out is null).to_be_false;
         if l_ts_data_out is not null then
            ut.expect(l_ts_data_out.count).to_equal(l_ts_data_in(1).count);
            if l_ts_data_out.count = l_ts_data_in(1).count then
               for j in 1..l_ts_data_out.count loop
                  ut.expect(l_ts_data_out(j).date_time).to_equal(l_ts_data_in(1)(j).date_time);
                  case i
                  when 1 then
                     ut.expect(l_ts_data_out(j).value).to_equal(l_ts_data_in(3)(j).value);
                  when 4 then
                     ut.expect(l_ts_data_out(j).value).to_equal(l_ts_data_in(1)(j).value);
                  else
                     ut.expect(l_ts_data_out(j).value).to_equal(l_ts_data_in(i)(j).value);
                  end case;
                  ut.expect(l_ts_data_out(j).quality_code).to_equal(l_ts_data_in(1)(j).quality_code);
               end loop;
            end if;
         end if;
      end loop;
   end test_retrieve_ts_raw;
   --------------------------------------------------------------------------------
   -- procedure test_retrieve_ts_f
   --------------------------------------------------------------------------------
   procedure test_retrieve_ts_f
   is
      type ztsv_array_tab is table of cwms_t_ztsv_array;
      l_lrts_data_local cwms_t_ztsv_array;
      l_lrts_data_utc   cwms_t_ztsv_array;
      l_lrts_id         cwms_v_ts_id.cwms_ts_id%type := test_base_location_id||'.Code.Inst.1DayLocal.0.Lrts';
      l_its_id          cwms_v_ts_id.cwms_ts_id%type := test_base_location_id||'.Code.Inst.~1Day.0.Its';
      l_unit_id         cwms_v_ts_id.unit_id%type := 'n/a';
      l_time_zone       cwms_v_ts_id.time_zone_id%type := 'US/Central';
      l_crsr            sys_refcursor;
      l_ts_id_out       cwms_v_ts_id.cwms_ts_id%type;
      l_unit_id_out     cwms_v_ts_id.unit_id%type;
      l_time_zone_out   cwms_v_ts_id.time_zone_id%type;
      l_dates           cwms_t_date_table;
      l_timestamps      cwms_t_timestamp_tab;
      l_tstzs           cwms_t_tstz_tab;
      l_values          cwms_t_double_tab;
      l_quality_codes   cwms_t_number_tab;
      l_count           binary_integer;
      ii                binary_integer;
   begin
      setup;
      cwms_ts.set_require_new_lrts_format_on_input('T');
      cwms_ts.set_use_new_lrts_format_on_output('T');
      ---------------------------------------------------------
      -- build an LRTS with gaps that crosses a DST boundary --
      ---------------------------------------------------------
      -- one copy in the local time zone
      l_lrts_data_local := ztsv_array();
      l_lrts_data_local.extend;
      l_lrts_data_local(1) := cwms_t_ztsv(timestamp '2024-02-15 07:00:00', 215, 0);
      for i in 1..31 loop
         continue when mod(i,3) = 0 or mod(i,5) = 0;
         l_lrts_data_local.extend;
         l_lrts_data_local(l_lrts_data_local.count) := cwms_t_ztsv(date '2024-02-29' + i + 7/24, 300+i, 0);
      end loop;
      l_lrts_data_local.extend;
      l_lrts_data_local(l_lrts_data_local.count) := cwms_t_ztsv(date '2024-04-15' + 7/24, 415, 0);
      -- another copy in UTC
      select cwms_t_ztsv(cwms_util.change_timezone(date_time, l_time_zone, 'UTC'), value, quality_code)
        bulk collect
        into l_lrts_data_utc
        from table(l_lrts_data_local);
      ------------------------
      -- store the location --
      ------------------------
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_active       => 'T',
         p_time_zone_id => l_time_zone,
         p_db_office_id => '&&office_id');
      commit;
      --------------------
      -- store the LRTS --
      --------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_lrts_id,
         p_units           => l_unit_id,
         p_timeseries_data => l_lrts_data_utc,
         p_store_rule      => cwms_util.replace_all,
         p_office_id       => '&&office_id');
      --------------------------------
      -- store the LRTS data as ITS --
      --------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_its_id,
         p_units           => l_unit_id,
         p_timeseries_data => l_lrts_data_utc,
         p_store_rule      => cwms_util.replace_all,
         p_office_id       => '&&office_id');
      ----------------------------
      -- test getting prev/next --
      ----------------------------
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f LRTS previous/next with inclusive = '||substr('TF', pass, 1));
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_lrts_id),
            p_start_time      => timestamp '2024-03-01 07:00:00',
            p_end_time        => timestamp '2024-03-31 07:00:00',
            p_time_zone       => null,
            p_date_time_type  => 'DATE',
            p_units           => upper(l_unit_id),
            p_unit_system     => 'EN',
            p_trim            => 'F',
            p_start_inclusive => substr('TF', pass, 1),
            p_end_inclusive   => substr('TF', pass, 1),
            p_previous        => 'T',
            p_next            => 'T',
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         fetch l_crsr
          bulk collect
          into l_dates,
               l_values,
               l_quality_codes;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_lrts_id);
         ut.expect(l_unit_id_out).to_equal(l_unit_id);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := case
                    when pass = 1 then
                       l_lrts_data_local(l_lrts_data_local.count).date_time - l_lrts_data_local(1).date_time + 1
                    else
                       31
                    end;
         ut.expect(l_dates.count).to_equal(l_count);
         if l_dates.count = l_count then
            ut.expect(l_dates(1)).to_equal(case when pass = 1 then date '2024-02-15' else date '2024-03-01' end + 7/24);
            ut.expect(l_values(1)).to_equal(case when pass = 1 then 215 else 301 end);
            ut.expect(l_quality_codes(1)).to_equal(0);
            for i in 2..l_count-1 loop
               ut.expect(l_dates(i)).to_equal(l_dates(i-1) + 1);
               if l_dates(i) between timestamp '2024-03-01 07:00:00' and timestamp '2024-03-31 07:00:00' then
                  ii := l_dates(i) - date '2024-03-01' + 7/24;
                  if mod(ii, 3) = 0 or mod(ii, 5) = 0 then
                     ut.expect(l_values(i)).to_be_null;
                  else
                     ut.expect(l_values(i)).to_equal(300 + ii);
                  end if;
               else
                  ut.expect(l_values(i)).to_be_null;
               end if;
               ut.expect(l_quality_codes(i)).to_equal(0);
            end loop;
            ut.expect(l_dates(l_count)).to_equal(case when pass = 1 then date '2024-04-15' else date '2024-03-31' end + 7/24);
            ut.expect(l_values(l_count)).to_equal(case when pass = 1 then 415 else 331 end);
            ut.expect(l_quality_codes(l_count)).to_equal(0);
         else
            for ii in 1..l_dates.count loop
               dbms_output.put_line('*** '||l_dates(ii));
            end loop;
         end if;
      end loop;
      ------------------------------
      -- test inclusive/exclusive --
      ------------------------------
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f LRTS start/end inclusive = '||substr('TF', pass, 1));
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_lrts_id),
            p_start_time      => timestamp '2024-03-01 07:00:00',
            p_end_time        => timestamp '2024-03-31 07:00:00',
            p_time_zone       => null,
            p_date_time_type  => 'DATE',
            p_units           => upper(l_unit_id),
            p_unit_system     => 'EN',
            p_trim            => 'F',
            p_start_inclusive => substr('TF', pass, 1), -- shouldn't matter if p_previous = 'T'
            p_end_inclusive   => substr('TF', pass, 1), -- shouldn't matter if p_next = 'T'
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         fetch l_crsr
          bulk collect
          into l_dates,
               l_values,
               l_quality_codes;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_lrts_id);
         ut.expect(l_unit_id_out).to_equal(l_unit_id);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := 31 - 2 * (pass-1);
         ut.expect(l_dates.count).to_equal(l_count);
         if l_dates.count = l_count then
            for i in 1..l_count loop
               if i = 1 then
                  ut.expect(l_dates(i)).to_equal(date '2024-03-01' + 7/24 + (pass - 1));
               else
                  ut.expect(l_dates(i)).to_equal(l_dates(i-1)+1);
               end if;
               ii := i + pass - 1;
               if mod(ii, 3) = 0 or mod(ii, 5) = 0 then
                  ut.expect(l_values(i)).to_be_null;
               else
                  ut.expect(l_values(i)).to_equal(300 + ii);
               end if;
               ut.expect(l_quality_codes(i)).to_equal(0);
            end loop;
         end if;
      end loop;
      ---------------
      -- test trim --
      ---------------
      dbms_output.put_line('==> Testing retrieve_ts_f LRTS trim = T');
      l_crsr := cwms_ts.retrieve_ts_f (
         p_cwms_ts_id_out  => l_ts_id_out,
         p_units_out       => l_unit_id_out,
         p_time_zone_id    => l_time_zone_out,
         p_cwms_ts_id      => upper(l_lrts_id),
         p_start_time      => date '2024-02-16',
         p_end_time        => date '2024-04-14',
         p_time_zone       => null,
         p_date_time_type  => 'DATE',
         p_units           => upper(l_unit_id),
         p_unit_system     => 'EN',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => null,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr
       bulk collect
       into l_dates,
            l_values,
            l_quality_codes;
      close l_crsr;

      ut.expect(l_ts_id_out).to_equal(l_lrts_id);
      ut.expect(l_unit_id_out).to_equal(l_unit_id);
      ut.expect(l_time_zone_out).to_equal(l_time_zone);
      l_count := 31;
      ut.expect(l_dates.count).to_equal(l_count);
      if l_dates.count = l_count then
         for i in 1..l_count loop
            if i = 1 then
               ut.expect(l_dates(i)).to_equal(date '2024-03-01' + 7/24);
            else
               ut.expect(l_dates(i)).to_equal(l_dates(i-1)+1);
            end if;
            if mod(i, 3) = 0 or mod(i, 5) = 0 then
               ut.expect(l_values(i)).to_be_null;
            else
               ut.expect(l_values(i)).to_equal(300 + i);
            end if;
            ut.expect(l_quality_codes(i)).to_equal(0);
         end loop;
      end if;
      --------------
      -- test ITS --
      --------------
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f ITS with prev/next = '||substr('TF', pass, 1));
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_its_id),
            p_start_time      => date '2024-02-16',
            p_end_time        => date '2024-04-14',
            p_time_zone       => null,
            p_date_time_type  => 'DATE',
            p_units           => upper(l_unit_id),
            p_unit_system     => 'EN',
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => substr('TF', pass, 1),
            p_next            => substr('TF', pass, 1),
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         fetch l_crsr
          bulk collect
          into l_dates,
               l_values,
               l_quality_codes;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_its_id);
         ut.expect(l_unit_id_out).to_equal(l_unit_id);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := l_lrts_data_local.count - (pass-1) * 2;
         ut.expect(l_dates.count).to_equal(l_count);
         if l_dates.count = l_count then
            for i in 1..l_count loop
               ii := i + pass - 1;
               ut.expect(l_dates(i)).to_equal(l_lrts_data_local(ii).date_time);
               ut.expect(l_values(i)).to_equal(l_lrts_data_local(ii).value);
               ut.expect(l_quality_codes(i)).to_equal(l_lrts_data_local(ii).quality_code);
            end loop;
         end if;
      end loop;
      -------------------------
      -- test date/time type --
      -------------------------
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f ITS date_time_type = '||case when pass = 1 then 'TIMESTAMP' else 'TIMESTAMP WITH TIME ZONE' end);
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_its_id),
            p_start_time      => l_lrts_data_local(1).date_time,
            p_end_time        => l_lrts_data_local(l_lrts_data_local.count).date_time,
            p_time_zone       => null,
            p_date_time_type  => case when pass = 1 then 'TIMESTAMP' else 'TIMESTAMP WITH TIME ZONE' end,
            p_units           => upper(l_unit_id),
            p_unit_system     => 'EN',
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         if pass = 1 then
            fetch l_crsr
             bulk collect
             into l_timestamps,
                  l_values,
                  l_quality_codes;
         else
            fetch l_crsr
             bulk collect
             into l_tstzs,
                  l_values,
                  l_quality_codes;
         end if;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_its_id);
         ut.expect(l_unit_id_out).to_equal(l_unit_id);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := l_lrts_data_local.count;
         if pass = 1 then
            ut.expect(l_timestamps.count).to_equal(l_count);
            if l_timestamps.count = l_count then
               for i in 1..l_count loop
                  ut.expect(l_timestamps(i)).to_equal(cast(l_lrts_data_local(i).date_time as timestamp));
                  ut.expect(l_values(i)).to_equal(l_lrts_data_local(i).value);
                  ut.expect(l_quality_codes(i)).to_equal(l_lrts_data_local(i).quality_code);
               end loop;
            end if;
         else
            ut.expect(l_tstzs.count).to_equal(l_count);
            if l_tstzs.count = l_count then
               for i in 1..l_count loop
                  ut.expect(l_tstzs(i)).to_equal(from_tz(cast(l_lrts_data_local(i).date_time as timestamp), l_time_zone));
                  ut.expect(l_values(i)).to_equal(l_lrts_data_local(i).value);
                  ut.expect(l_quality_codes(i)).to_equal(l_lrts_data_local(i).quality_code);
               end loop;
            end if;
         end if;
      end loop;
      --------------------
      -- test time zone --
      --------------------
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f ITS time zone = '||case when pass = 1 then 'UTC' else 'US/Pacific' end);
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_its_id),
            p_start_time      => date '2024-02-01',
            p_end_time        => date '2024-05-01',
            p_time_zone       => case when pass = 1 then 'UTC' else 'US/Pacific' end,
            p_date_time_type  => 'DATE',
            p_units           => upper(l_unit_id),
            p_unit_system     => 'EN',
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         fetch l_crsr
          bulk collect
          into l_dates,
               l_values,
               l_quality_codes;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_its_id);
         ut.expect(l_unit_id_out).to_equal(l_unit_id);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := l_lrts_data_local.count;
         ut.expect(l_dates.count).to_equal(l_count);
         if l_dates.count = l_count then
            for i in 1..l_count loop
               if pass = 1 then
                  ut.expect(l_dates(i)).to_equal(l_lrts_data_utc(i).date_time);
               else
                  ut.expect(l_dates(i)).to_equal(l_lrts_data_local(i).date_time - 2/24);
               end if;
               ut.expect(l_values(i)).to_equal(l_lrts_data_local(i).value);
               ut.expect(l_quality_codes(i)).to_equal(l_lrts_data_local(i).quality_code);
            end loop;
         end if;
      end loop;
      ------------------------
      -- test default units --
      ------------------------
      cwms_display.store_unit('Code', 'EN', '%', 'F', '&&office_id');
      for pass in 1..2 loop
         dbms_output.put_line('==> Testing retrieve_ts_f ITS default units for unit system = '||case when pass = 1 then 'SI' else 'EN' end);
         l_crsr := cwms_ts.retrieve_ts_f (
            p_cwms_ts_id_out  => l_ts_id_out,
            p_units_out       => l_unit_id_out,
            p_time_zone_id    => l_time_zone_out,
            p_cwms_ts_id      => upper(l_its_id),
            p_start_time      => date '2024-02-01',
            p_end_time        => date '2024-05-01',
            p_time_zone       => null,
            p_date_time_type  => 'DATE',
            p_units           => null,
            p_unit_system     => case when pass = 1 then 'SI' else 'EN' end,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => null,
            p_max_version     => 'T',
            p_office_id       => '&&office_id');

         fetch l_crsr
          bulk collect
          into l_dates,
               l_values,
               l_quality_codes;
         close l_crsr;

         ut.expect(l_ts_id_out).to_equal(l_its_id);
         ut.expect(l_unit_id_out).to_equal(case when pass = 1 then 'n/a' else '%' end);
         ut.expect(l_time_zone_out).to_equal(l_time_zone);
         l_count := l_lrts_data_local.count;
         ut.expect(l_dates.count).to_equal(l_count);
         if l_dates.count = l_count then
            for i in 1..l_count loop
               ut.expect(l_dates(i)).to_equal(l_lrts_data_local(i).date_time);
               ut.expect(l_values(i)).to_equal(l_lrts_data_local(i).value * case when pass = 1 then 1 else 100 end);
               ut.expect(l_quality_codes(i)).to_equal(l_lrts_data_local(i).quality_code);
            end loop;
         end if;
      end loop;
      cwms_display.delete_unit('Code', 'EN', '&&office_id');
      cwms_ts.set_require_new_lrts_format_on_input('F');
      cwms_ts.set_use_new_lrts_format_on_output('F');
   end test_retrieve_ts_f;

   --------------------------------------------------------------------------------
   -- procedure test_cwms_v_ts_id_access
   --------------------------------------------------------------------------------
   procedure test_cwms_v_ts_id_access
   is
      l_count     binary_integer;
      l_ts_id     varchar2 (191) := test_base_location_id || '.Code.Inst.1Hour.0.Test';
      l_loc_id    varchar2 (57) := test_base_location_id;
      l_unit      varchar2 (16) := 'n/a';
      l_office_id varchar2 (16) := '&&office_id';
      l_ts_data   cwms_t_ztsv_array := cwms_t_ztsv_array (
                     cwms_t_ztsv (date '2021-10-01' + 1 / 24, 1, 0),
                     cwms_t_ztsv (date '2021-10-01' + 2 / 24, 2, 0),
                     cwms_t_ztsv (date '2021-10-01' + 3 / 24, 3, 0),
                     cwms_t_ztsv (date '2021-10-01' + 4 / 24, 4, 0),
                     cwms_t_ztsv (date '2021-10-01' + 5 / 24, 5, 0),
                     cwms_t_ztsv (date '2021-10-01' + 6 / 24, 6, 0));
   begin
       -------------------------
       -- store a time series --
       -------------------------
       cwms_loc.store_location(
         p_location_id    => l_loc_id,
         p_db_office_id   => l_office_id);

       cwms_ts.zstore_ts(
         p_cwms_ts_id        => l_ts_id,
         p_units             => l_unit,
         p_timeseries_data   => l_ts_data,
         p_store_rule        => cwms_util.replace_all,
         p_office_id         => l_office_id);

      ---------------------------------------
      -- verify we can see the time series --
      ---------------------------------------
      select count(*) into l_count from cwms_v_ts_id where cwms_ts_id = l_ts_id;
      ut.expect(l_count).to_equal(1);

   end test_cwms_v_ts_id_access;
   --------------------------------------------------------------------------------
   -- procedure    procedure test_cwdb_289_retrieve_ts_with_session_timezone_not_utc
   --------------------------------------------------------------------------------
   procedure test_cwdb_289_retrieve_ts_with_session_timezone_not_utc
   is
      l_ts_id           varchar2 (191) := test_base_location_id || '.Code.Inst.1Hour.0.Test';
      l_loc_id          varchar2 (57) := test_base_location_id;
      l_unit            varchar2 (16) := 'n/a';
      l_office_id       varchar2 (16) := '&&office_id';
      l_ts_data         cwms_t_ztsv_array := cwms_t_ztsv_array();
      l_ts_count        binary_integer := 48;
      l_ts_count2       binary_integer;
      l_session_tzs     cwms_t_str_tab := cwms_t_str_tab('UTC', 'US/Central');
      l_retrieve_tzs    cwms_t_str_tab := cwms_t_str_tab('UTC', 'US/Pacific', 'Europe/Bucharest', 'America/Santiago', 'Australia/Sydney');
      l_start_dates     cwms_t_date_table := cwms_t_date_table(
                                                date '2024-03-10',  -- Spring boundary for US/Pacific       ( -8 ->  -7)
                                                date '2024-03-31',  -- Spring boundary for Europe/Bucharest ( +2 ->  +3)
                                                date '2024-04-06',  -- Spring boundary for Autralia/Sydney  (+10 ->  +9) and America/Santiago (-3 -> -4)
                                                date '2024-09-09',  -- Fall boundary for America/Santiago   ( -4 ->  -3)
                                                date '2024-10-06',  -- Fall boudnary for Autralia/Sydney    ( +9 -> +10)
                                                date '2024-10-27',  -- Fall boundary for Europe/Bucharest   ( +3 ->  +2)
                                                date '2024-11-03'); -- Fall boundary for US/Pacific         ( -7 ->  -8)
      l_date_time_types cwms_t_str_tab := cwms_t_str_tab('DATE', 'TIMESTAMP', 'TIMESTAMP WITH TIME ZONE');
      l_session_tz      varchar2(128);
      l_crsr            sys_refcursor;
      l_ts_id_out       cwms_v_ts_id.cwms_ts_id%type;
      l_unit_id_out     cwms_v_ts_id.unit_id%type;
      l_time_zone_out   cwms_v_ts_id.time_zone_id%type;
      l_dates           cwms_t_date_table;
      l_timestamps      cwms_t_timestamp_tab;
      l_timestamp_tzs   cwms_t_tstz_tab;
      l_values          cwms_t_double_tab;
      l_qualities       cwms_t_number_tab;
      l_exp_date        date;
      l_exp_ts          timestamp;
      l_exp_tstz        timestamp with time zone;
   begin
      -------------------------
      -- create the location --
      -------------------------
      cwms_loc.store_location(
         p_location_id    => l_loc_id,
         p_db_office_id   => l_office_id);
      --------------------
      -- create ts data --
      --------------------
      l_ts_data.extend(l_ts_count * l_start_dates.count);
      for i in 1..l_start_dates.count loop
         for j in 1..l_ts_count loop
            l_ts_data((i-1)*l_ts_count+j) := cwms_t_ztsv(l_start_dates(i) - 1 + j/24, j, 3);
         end loop;
      end loop;
      cwms_ts.zstore_ts(
         p_cwms_ts_id        => l_ts_id,
         p_units             => l_unit,
         p_timeseries_data   => l_ts_data,
         p_store_rule        => cwms_util.replace_all,
         p_office_id         => l_office_id);
      ----------------------------------------------------------------------
      -- retrieve the data using various session and retrieval time zones --
      ----------------------------------------------------------------------
      for i in 1..l_session_tzs.count loop
         execute immediate 'alter session set time_zone = '''||l_session_tzs(i)||'''';
         select sessiontimezone into l_session_tz from dual;
         ut.expect(l_session_tz).to_equal(l_session_tzs(i));
         dbms_output.put_line('==> Session time zone = '||l_session_tzs(i));
         for j in 1..l_retrieve_tzs.count loop
            dbms_output.put_line('==> Retrieve time zone '||l_retrieve_tzs(j));
            for k in 1..l_date_time_types.count loop
               dbms_output.put_line('==> Date_Time Type = '||l_date_time_types(k));
               for m in 1..l_start_dates.count loop
                  begin
                     dbms_output.put_line('==> Retrieving '||(l_start_dates(m) - 1)||' - '||(l_start_dates(m) + l_ts_count/24 + 1)||' '||l_retrieve_tzs(j));
                     l_crsr := cwms_ts.retrieve_ts_f (
                        p_cwms_ts_id_out  => l_ts_id_out,
                        p_units_out       => l_unit_id_out,
                        p_time_zone_id    => l_time_zone_out,
                        p_cwms_ts_id      => l_ts_id,
                        p_start_time      => l_start_dates(m) - 2,
                        p_end_time        => l_start_dates(m) + 2,
                        p_time_zone       => l_retrieve_tzs(j),
                        p_date_time_type  => l_date_time_types(k),
                        p_units           => l_unit,
                        p_trim            => 'T',
                        p_office_id       => '&&office_id');

                     case
                     when l_date_time_types(k) = 'DATE' then
                        l_dates := cwms_t_date_table();
                        fetch l_crsr
                         bulk collect
                         into l_dates,
                              l_values,
                              l_qualities;
                        close l_crsr;
                        ut.expect(l_dates.count).to_equal(l_ts_count);
                        if l_dates.count = l_ts_count then
                           for n in 1..l_ts_count loop
                              l_exp_date := cwms_util.change_timezone(l_ts_data(n+(m-1)*l_ts_count).date_time, 'UTC', l_retrieve_tzs(j));
                              if l_exp_date is null then
                                 l_exp_date := cwms_util.change_timezone(l_ts_data(n+(m-1)*l_ts_count).date_time - 1/86400, 'UTC', l_retrieve_tzs(j)) + 1/86400;
                              end if;
                              if l_exp_date is null then
                                 l_exp_date := cwms_util.change_timezone(l_ts_data(n+(m-1)*l_ts_count).date_time + 1/86400, 'UTC', l_retrieve_tzs(j)) - 1/86400;
                              end if;
                              ut.expect(l_dates(n)).to_equal(l_exp_date);
                              ut.expect(l_values(n)).to_equal(l_ts_data(n).value);
                           end loop;
                        end if;
                     when l_date_time_types(k) = 'TIMESTAMP' then
                        l_timestamps := cwms_t_timestamp_tab();
                        fetch l_crsr
                         bulk collect
                         into l_timestamps,
                              l_values,
                              l_qualities;
                        close l_crsr;
                        ut.expect(l_timestamps.count).to_equal(l_ts_count);
                        if l_timestamps.count = l_ts_count then
                           for n in 1..l_ts_count loop
                              l_exp_ts := cwms_util.change_timezone(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp), 'UTC', l_retrieve_tzs(j));
                              if l_exp_ts is null then
                                 l_exp_ts := cwms_util.change_timezone(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp) - interval '0 0:0:1' day to second, 'UTC', l_retrieve_tzs(j)) + interval '0 0:0:1' day to second;
                              end if;
                              if l_exp_ts is null then
                                 l_exp_ts := cwms_util.change_timezone(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp) + interval '0 0:0:1' day to second, 'UTC', l_retrieve_tzs(j)) - interval '0 0:0:1' day to second;
                              end if;
                              ut.expect(l_timestamps(n)).to_equal(l_exp_ts);
                              ut.expect(l_values(n)).to_equal(l_ts_data(n).value);
                           end loop;
                        end if;
                     when l_date_time_types(k) = 'TIMESTAMP WITH TIME ZONE' then
                        l_timestamp_tzs := cwms_t_tstz_tab();
                        fetch l_crsr
                         bulk collect
                         into l_timestamp_tzs,
                              l_values,
                              l_qualities;
                        close l_crsr;
                        ut.expect(l_timestamp_tzs.count).to_equal(l_ts_count);
                        if l_timestamp_tzs.count = l_ts_count then
                           for n in 1..l_ts_count loop
                              l_exp_tstz := from_tz(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp), 'UTC') at time zone l_retrieve_tzs(j);
                              if l_exp_tstz is null then
                                 l_exp_tstz := from_tz(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp) - interval '0 0:0:1' day to second, 'UTC') at time zone l_retrieve_tzs(j) + interval '0 0:0:1' day to second;
                              end if;
                              if l_exp_tstz is null then
                                 l_exp_tstz := from_tz(cast(l_ts_data(n+(m-1)*l_ts_count).date_time as timestamp) + interval '0 0:0:1' day to second, 'UTC') at time zone l_retrieve_tzs(j) - interval '0 0:0:1' day to second;
                              end if;
                              ut.expect(l_timestamp_tzs(n)).to_equal(l_exp_tstz);
                              ut.expect(l_values(n)).to_equal(l_ts_data(n).value);
                           end loop;
                        end if;
                     end case;
                  exception
                     when others then
                        dbms_output.put_line(dbms_utility.format_error_backtrace);
                        ut.expect(sqlerrm).to_be_null;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;

      execute immediate 'alter session set time_zone = ''UTC''';
      select sessiontimezone into l_session_tz from dual;
      ut.expect(l_session_tz).to_equal('UTC');

   end test_cwdb_289_retrieve_ts_with_session_timezone_not_utc;

END test_cwms_ts;
/
SHOW ERRORS