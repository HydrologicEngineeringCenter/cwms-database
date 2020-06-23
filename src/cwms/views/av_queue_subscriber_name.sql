insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_QUEUE_SUBSCRIBER_NAME', null,
'
/**
 * Holds registered subscribers for queue messages
 *
 * @since CWMS 3.0
 *
 * @field office_id         The office that owns the queue
 * @field queue_name        The queue the subscription is for
 * @field subscriber_name   The subscriber name
 * @field create_time       The time the subscriber was created
 * @field update_time       The last time the subscriber was updated with another pid
 * @field db_user           The session user that created the subscriber
 * @field os_user           The client OS user that created the subscriber
 * @field host_name         The name of the client system that created the subscriber
 * @field application_name  The application name assosicated with the subscriber
 * @field os_process_id     The process identifier (pid) associated with the subscriber
 */
');

create or replace force view av_queue_subscriber_name (
   office_id,
   queue_name,
   subscriber_name,
   create_time_utc,
   last_update_time_utc,
   db_user,
   os_user,
   host_name,
   application_name,
   os_process_id
) as
select substr(queue_name, 1, instr(queue_name, '_')-1) as office_id,
       substr(queue_name, instr(queue_name, '_')+1) as queue_name,
       subscriber_name,
       create_time as create_time_utc,
       update_time as last_update_time_utc,
       db_user,
       os_user,
       host_name,
       application_name,
       os_process_id
  from at_queue_subscriber_name;

create public synonym cwms_v_queue_subscriber_name for cwms_20.av_queue_subscriber_name;
begin
	execute immediate 'grant select on av_queue_subscriber_name to cwms_user';
exception
	when others then null;
end;
/


