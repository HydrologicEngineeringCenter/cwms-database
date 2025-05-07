CREATE OR REPLACE PACKAGE &cwms_schema..test_aq_user AUTHID CURRENT_USER 
AS
    -- %suite(Test AQ system for Normal user )
    --%beforeall(setup)
    --%afterall(teardown)
    --%rollback(manual)

    -- %test (Store Data)
    PROCEDURE test_store_data;

    
    PROCEDURE teardown;

    PROCEDURE setup;

    test_base_location_id   VARCHAR2 (256) := 'TestLoc1';
    test_cwms_ts_id VARCHAR2(512) := test_base_location_id || '.Stage.Inst.0.0.ver';
    test_log_message VARCHAR2(512) := 'Test Message random';
    test_subscriber_name VARCHAR2(64) := 'TEST_USER_SUB';
    already_subbed EXCEPTION;
    PRAGMA EXCEPTION_INIT(already_subbed,-24034);
    
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_aq_user
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

    END;

    PROCEDURE setup
    IS
    BEGIN        
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;
        begin
            dbms_aqadm.add_subscriber(queue_name=>'&cwms_schema..&office_id._TS_STORED', 
                                    subscriber=>SYS.AQ$_AGENT(test_subscriber_name,'&cwms_schema..&office_id._TS_STORED',
                                    NULL));
        exception
            when already_subbed then null;
        end;
    END;

    

    PROCEDURE test_store_data           
    IS
        payload sys.aq$_jms_map_message;
        options dbms_aq.dequeue_options_t;
        props dbms_aq.message_properties_t;
        payload_op pls_integer;
        the_type varchar(500);
        the_id varchar(500);
        opId pls_integer;
        msgid raw(16);
    BEGIN
        

        cwms_ts.create_ts('&office_id',test_cwms_ts_id,NULL);

        options.consumer_name := test_subscriber_name;
        options.navigation := dbms_aq.FIRST_MESSAGE;
        options.msgid := null;
        options.wait := 120; -- update to 2 minutes
        dbms_aq.dequeue(queue_name=>'&cwms_schema..&office_id._TS_STORED', dequeue_options => options,message_properties=>props,payload=>payload,msgid=>msgid);
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
