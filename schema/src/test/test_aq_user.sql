CREATE OR REPLACE PACKAGE &cwms_schema..test_aq_user
AS
    -- %suite(Test AQ system for Normal user )
    --%beforeall(setup)
    --%afterall(teardown)
    --%rollback(manual)

    -- %test (Store Data)
    PROCEDURE test_store_data;

    
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
            cwms_ts.delete_ts(test_cwms_ts_id,cwms_util.delete_ts_cascade,'&office_id');
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

    

    PROCEDURE test_store_data            
    IS
        payload sys.aq$_jms_map_message;
        options dbms_aq.dequeue_options_t;
        payload_op pls_integer;
        the_type varchar(500);
        the_id varchar(500);
        opId pls_integer;
    
    BEGIN
        dbms_aqadm.add_subscriber(queue_name=>'&cwms_schema..&office_id_TS_STORED', 
                                  subscriber=>SYS.AQ$_AGENT('TEST','&cwms_schema..&office_id_TS_STORED',
                                  NULL));

        cwms_ts.create_ts('&office_id',test_cwms_ts_id,NULL);

        options.consumer_name := 'TEST';
        options.navigation := dbms_aq.FIRST_MESSAGE;
        options.msgid := null;
        dbms_aq.dequeue(queue_name=>'&cwms_schema..&office_id_TS_STORED', dequeue_options => options,message_properties=>props,payload=>payload,msgid=>msgid);
        dbms_output.put_line('Have message, now doing something with it.');
        opId := payload.prepare(-1);
        dbms_output.put_line('Message Prepared');
        payload.get_string(opId,'type',the_type);
        dbms_output.put_line('TYPE' || the_type);
        payload.get_string(opId,'ts_id',the_id);
        ut.expect(the_id).to_equal(test_cwms_ts_id);
        
    END;
END;
/
