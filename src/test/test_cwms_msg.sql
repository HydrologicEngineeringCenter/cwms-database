CREATE OR REPLACE PACKAGE CWMS_20.test_cwms_msg
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

CREATE OR REPLACE PACKAGE BODY CWMS_20.test_cwms_msg
AS
    PROCEDURE teardown
    IS
    BEGIN
        delete  from at_log_message_properties where msg_id in (select msg_id from at_log_message where msg_text =test_log_message);
        delete  from at_log_message where msg_text =test_log_message;

        DELETE FROM AT_PROPERTIES
              WHERE prop_id=cwms_msg.msg_timeout_prop;

        BEGIN
         	DBMS_AQADM.remove_subscriber (
                	'&office_id._TS_STORED',
                	sys.AQ$_AGENT (test_subscriber_name, '&office_id._TS_STORED', 0));
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        BEGIN
        	cwms_loc.delete_location_cascade(test_base_location_id,'&office_id');
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        DBMS_SCHEDULER.enable ('&cwms_schema..REMOVE_DEAD_SUBSCRIBERS_JOB');
        COMMIT;
    END;

    PROCEDURE setup
    IS
    BEGIN
        EXECUTE IMMEDIATE 'alter trigger cwms_20.ST_PROPERTIES disable';

        --BEGIN
        INSERT INTO at_properties
             VALUES (53,
                     'CWMSDB',
                     cwms_msg.msg_timeout_prop,
                     '1',
                     'Set message time out to 1 sec');

        COMMIT;
        --EXCEPTION WHEN OTHERS THEN NULL; END;

        EXECUTE IMMEDIATE 'alter trigger cwms_20.ST_PROPERTIES enable';

        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;
        DBMS_SCHEDULER.disable ('CWMS_20.REMOVE_DEAD_SUBSCRIBERS_JOB');
    END;

    PROCEDURE test_remove_subscribers
    IS
        p_times        CWMS_TS.NUMBER_ARRAY;
        p_values       CWMS_TS.DOUBLE_ARRAY;
        p_qualities    CWMS_TS.NUMBER_ARRAY;
        l_count        NUMBER;
        agent            sys.aq$_agent;
        test_agent_list  DBMS_AQ.aq$_agent_list_t;
    BEGIN
        DBMS_AQADM.add_subscriber (
            queue_name   => '&office_id._TS_STORED',
            subscriber   => sys.AQ$_AGENT (test_subscriber_name, NULL, NULL));


        test_agent_list(1) := sys.aq$_agent(test_subscriber_name, 'CWMS_20.&office_id._TS_STORED',  NULL);

        BEGIN
		DBMS_AQ.LISTEN( agent_list   =>   test_agent_list, wait=> 0, agent        =>   agent);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        select count(*) into l_count from AQ$&office_id._TS_STORED_TABLE_S where NAME=test_subscriber_name;

        ut.expect (1).to_equal (l_count);




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
                              '&office_id.',
                              'F');
        END LOOP;
    DBMS_LOCK.sleep (10);
    CWMS_MSG.REMOVE_DEAD_SUBSCRIBERS;

    select count(*) into l_count from AQ$&office_id._TS_STORED_TABLE_S where NAME=test_subscriber_name;

    ut.expect (0).to_equal (l_count);
    END;

    PROCEDURE test_log_db_message
    IS
        l_count   NUMBER;
    BEGIN
        cwms_msg.log_db_message (cwms_msg.msg_level_normal,
                                 test_log_message);

        SELECT COUNT (*)
          INTO l_count
          FROM AV_LOG_MESSAGE
         WHERE COMPONENT = 'CWMSDB' AND MSG_TEXT = test_log_message;

        ut.expect (1).to_equal (l_count);
    END;
END;
/
