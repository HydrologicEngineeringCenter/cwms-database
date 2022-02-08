insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATAEXCHANGE_JOB', null,
'
/**
 * Displays information on dataexchange batch jobs
 *
 * @since CWMS 2.1
 *
 * @field job_id         Unique job identifier created by requester
 * @field requested_from Entity requesting job
 * @field set_id         Identifies data exchange set for job
 * @field direction      Identifies direction of data exchange
 * @field request_time   Time that request was generated
 * @field start_time     Time that execution was started
 * @field end_time       Time that execution completed
 * @field start_delay    Time between request and start of execution
 * @field execution_time Time between execution start and end
 * @field total_time     Time between request and execution end
 * @field processed_by   Entity that executed data exchange
 * @field results        Text describing result of job execution
 */
');
CREATE OR REPLACE FORCE VIEW av_dataexchange_job
AS
    WITH request$
          AS (SELECT    p1.msg_id, p1.prop_text AS job_id,
                            p3.prop_text AS set_id, p4.prop_text AS to_dss,
                            m.log_timestamp_utc, o.office_id, m.HOST
                  FROM    at_log_message m,
                            cwms_office o,
                            at_log_message_properties p1,
                            at_log_message_properties p2,
                            at_log_message_properties p3,
                            at_log_message_properties p4,
                            cwms_log_message_types t
                 WHERE         p1.prop_name = 'job_id'
                            AND p2.prop_name = 'subtype'
                            AND p3.prop_name = 'set_id'
                            AND p4.prop_name = 'to_dss'
                            AND p2.prop_text = 'BatchExchange'
                            AND p2.msg_id = p1.msg_id
                            AND p3.msg_id = p1.msg_id
                            AND p4.msg_id = p1.msg_id
                            AND t.message_type_id = 'RequestAction'
                            AND m.msg_type = t.message_type_code
                            AND m.msg_id = p1.msg_id
                            AND o.office_code = m.office_code),
          start$
          AS (SELECT    p1.msg_id, p1.prop_text AS job_id, m.log_timestamp_utc
                  FROM    at_log_message m,
                            cwms_office o,
                            at_log_message_properties p1,
                            at_log_message_properties p2,
                            cwms_log_message_types t
                 WHERE         p1.prop_name = 'job_id'
                            AND p2.prop_name = 'subtype'
                            AND p2.prop_text = 'BatchStarting'
                            AND p2.msg_id = p1.msg_id
                            AND t.message_type_id = 'Status'
                            AND m.msg_type = t.message_type_code
                            AND m.msg_id = p1.msg_id
                            AND o.office_code = m.office_code),
          complete$
          AS (SELECT    p1.msg_id, p1.prop_text AS job_id, m.log_timestamp_utc,
                            m.instance, m.msg_text
                  FROM    at_log_message m,
                            cwms_office o,
                            at_log_message_properties p1,
                            at_log_message_properties p2,
                            cwms_log_message_types t
                 WHERE         p1.prop_name = 'job_id'
                            AND p2.prop_name = 'subtype'
                            AND p2.prop_text = 'BatchCompleted'
                            AND p2.msg_id = p1.msg_id
                            AND t.message_type_id = 'Status'
                            AND m.msg_type = t.message_type_code
                            AND m.msg_id = p1.msg_id
                            AND o.office_code = m.office_code)
    SELECT      request$.job_id, request$.HOST AS requested_from,
                  request$.office_id || '/' || request$.set_id AS set_id,
                  CASE request$.to_dss WHEN 'true' THEN 'extract' WHEN 'false' THEN 'post' END AS direction,
                  request$.log_timestamp_utc AS request_time,
                  start$.log_timestamp_utc AS start_time,
                  complete$.log_timestamp_utc AS end_time,
                  start$.log_timestamp_utc - request$.log_timestamp_utc AS start_delay,
                  complete$.log_timestamp_utc - start$.log_timestamp_utc AS execution_time,
                  complete$.log_timestamp_utc - request$.log_timestamp_utc AS total_time,
                  complete$.instance AS processed_by, complete$.msg_text AS results
         FROM   request$
                  LEFT OUTER JOIN start$
                      ON start$.job_id = request$.job_id
                  LEFT OUTER JOIN complete$
                      ON complete$.job_id = request$.job_id
    ORDER BY   request$.log_timestamp_utc DESC;

/