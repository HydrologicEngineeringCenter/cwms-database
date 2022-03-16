CREATE OR REPLACE PACKAGE &cwms_schema..test_cwms_msg
AS
    -- %suite(Test cwms msg package )
    --%beforeall(setup)
    --%afterall(teardown)
    --%rollback(manual)

    -- %test (store log message)
    PROCEDURE test_log_db_message;

    -- %test (test remove subscribers)
    PROCEDURE test_remove_subscribers;

    PROCEDURE teardown;

    PROCEDURE setup;

    test_base_location_id   VARCHAR2 (32) := 'TestLoc1';
    test_cwms_ts_id VARCHAR2(200) := test_base_location_id || '.Stage.Inst.0.0.ver';
    test_log_message VARCHAR2(64) := 'Test Message random';
    test_subscriber_name VARCHAR2(8) := 'TEST_SUB';
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_msg
AS
    PROCEDURE teardown
    IS
    BEGIN
        DELETE FROM at_log_message_properties
              WHERE msg_id IN (SELECT msg_id
                                 FROM at_log_message
                                WHERE msg_text = test_log_message);

        DELETE FROM at_log_message
              WHERE msg_text = test_log_message;

        DELETE FROM AT_PROPERTIES
              WHERE prop_id = cwms_msg.msg_timeout_prop;

        BEGIN
            DBMS_AQADM.remove_subscriber (
                '&office_id._TS_STORED',
                sys.AQ$_AGENT (test_subscriber_name, '&office_id._TS_STORED', 0));
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        BEGIN
            cwms_loc.delete_location_cascade (test_base_location_id, '&office_id');
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        DBMS_SCHEDULER.enable ('&cwms_schema..REMOVE_DEAD_SUBSCRIBERS_JOB');
        COMMIT;
        cwms_properties.set_property ('CWMSDB',
                                    cwms_msg.msg_timeout_prop,
                                    CWMS_MSG.msg_timeout_seconds,
                                    'Reset timeout threshold',
                                    'CWMS');

    END;

    PROCEDURE setup
    IS
    BEGIN

        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;
        DBMS_SCHEDULER.disable ('&cwms_schema..REMOVE_DEAD_SUBSCRIBERS_JOB');
    END;

    PROCEDURE test_remove_subscribers
    IS
        p_times           CWMS_TS.NUMBER_ARRAY;
        p_values          CWMS_TS.DOUBLE_ARRAY;
        p_qualities       CWMS_TS.NUMBER_ARRAY;
        l_count           NUMBER;
        agent             SYS.AQ$_AGENT;
        test_agent_list   DBMS_AQ.AQ$_AGENT_LIST_T;
    BEGIN
        DBMS_AQADM.add_subscriber (
            queue_name   => '&office_id._TS_STORED',
            subscriber   => sys.AQ$_AGENT (test_subscriber_name, NULL, NULL));


        test_agent_list (1) :=
            sys.AQ$_AGENT (test_subscriber_name,
                           '&cwms_schema..&office_id._TS_STORED',
                           NULL);

        BEGIN
            DBMS_AQ.LISTEN (agent_list   => test_agent_list,
                            wait         => 0,
                            agent        => agent);
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        SELECT COUNT (*)
          INTO l_count
          FROM AQ$&office_id._TS_STORED_TABLE_S
         WHERE NAME = test_subscriber_name;

        ut.expect (1).to_equal (l_count);

        SELECT COUNT (*)
          INTO l_count
          FROM dba_queue_subscribers
         WHERE owner = upper('&cwms_schema') AND consumer_name = test_subscriber_name;

        ut.expect (1).to_equal (l_count);
        cwms_properties.set_property ('CWMSDB',
                                    cwms_msg.msg_timeout_prop,
                                    120,
                                    'Set lower timeout threshold',
                                    'CWMS');

        FOR idx IN 1 .. 200
        LOOP
            p_times (1) := CWMS_UTIL.TO_MILLIS (SYSDATE + idx) + 3600 * 1000;
            p_values (1) := idx;
            p_qualities (1) := 10;

            CWMS_TS.STORE_TS (test_cwms_ts_id,
                              'FT',
                              p_times,
                              p_values,
                              p_qualities,
                              'Delete Insert',
                              'F',
                              cwms_util.non_versioned,
                              '&office_id',
                              'F');
        END LOOP;

        SELECT COUNT (*) INTO l_count FROM &office_id._ts_stored_table;

        ut.expect (201).to_equal (l_count);
        DBMS_LOCK.sleep (150);

        SELECT COUNT (*) INTO l_count FROM &office_id._ts_stored_table;

        ut.expect (0).to_equal (l_count);

        SELECT COUNT (*) INTO l_count FROM &office_id._ex_table;

        ut.expect (201).to_equal (l_count);
        CWMS_MSG.REMOVE_DEAD_SUBSCRIBERS;

        SELECT COUNT (*)
          INTO l_count
          FROM dba_queue_subscribers
         WHERE owner = upper('&cwms_schema') AND consumer_name = test_subscriber_name;

        ut.expect (0).to_equal (l_count);

        SELECT COUNT (*) INTO l_count FROM &office_id._ex_table;

        ut.expect (0).to_equal (l_count);
    END;

    PROCEDURE test_log_db_message
    IS
        l_count   NUMBER;
    BEGIN
        cwms_msg.log_db_message (cwms_msg.msg_level_normal, test_log_message);

        SELECT COUNT (*)
          INTO l_count
          FROM AV_LOG_MESSAGE
         WHERE COMPONENT = 'CWMSDB' AND MSG_TEXT = test_log_message;

        ut.expect (1).to_equal (l_count);
    END;
END;
/

