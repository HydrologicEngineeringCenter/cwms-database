declare
   l_count pls_integer;
begin
   select count(*)
     into l_count
     from user_tables
    where table_name = 'AT_QUEUE_SUBSCRIBER_NAME';
    
   if l_count = 0 then
      execute immediate '
         create table at_queue_subscriber_name (
            subscriber_name  varchar2(30) primary key,
            queue_name       varchar2(30) not null,
            create_time      timestamp    not null,
            update_time      timestamp,
            db_user          varchar2(30) not null,
            os_user          varchar2(30) not null,
            host_name        varchar2(64) not null,
            application_name varchar2(48) not null,
            os_process_id    integer      not null
         )
         tablespace cwms_20at_data';
      execute immediate 'comment on table  at_queue_subscriber_name is ''Holds registered subscribers for queue messages''';
      execute immediate 'comment on column at_queue_subscriber_name.subscriber_name   is ''The subscriber name''';
      execute immediate 'comment on column at_queue_subscriber_name.queue_name        is ''The queue the subscription is for''';
      execute immediate 'comment on column at_queue_subscriber_name.create_time       is ''The time the subscriber was created''';
      execute immediate 'comment on column at_queue_subscriber_name.update_time       is ''The last time the subscriber was updated with another pid''';
      execute immediate 'comment on column at_queue_subscriber_name.db_user           is ''The session user that created the subscriber''';
      execute immediate 'comment on column at_queue_subscriber_name.os_user           is ''The client OS user that created the subscriber''';
      execute immediate 'comment on column at_queue_subscriber_name.host_name         is ''The name of the client system that created the subscriber''';
      execute immediate 'comment on column at_queue_subscriber_name.application_name  is ''The application name assosicated with the subscriber''';
      execute immediate 'comment on column at_queue_subscriber_name.os_process_id     is ''The process identifier (pid) associated with the subscriber''';
      execute immediate 'create index at_queue_subscriber_name_idx1 on at_queue_subscriber_name (queue_name, nvl(update_time, create_time))';
   end if;
end;   
   


