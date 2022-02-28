 BEGIN
    "${CWMS_SCHEMA}"."CWMS_MSG"."CREATE_QUEUES" ('${CWMS_OFFICE_ID}');
    "${CWMS_SCHEMA}"."CWMS_MSG"."CREATE_EXCEPTION_QUEUE" ('${CWMS_OFFICE_ID}');

    cwms_msg.create_av_queue_subscr_msgs; -- view must be created after creating queues

END;
/