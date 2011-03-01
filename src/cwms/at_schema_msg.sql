SET define on
@@defines.sql

-----------------------------
-- AT_TS_MSG_ARCHIVE_1 table
--
create table at_ts_msg_archive_1
(
   msg_id          varchar2(32)  not null,
   ts_code         number(10)    not null,
   message_time    timestamp(6)  not null,
   first_data_time date          not null,
   last_data_time  date          not null
)
TABLESPACE CWMS_20AT_DATA
pctused    0
pctfree    10
initrans   1
maxtrans   255
storage    (
            initial          5m
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
logging 
nocompress 
nocache
noparallel
monitoring;

-----------------------------
-- AT_TS_MSG_ARCHIVE_1 comments
--
comment on table  at_ts_msg_archive_1                 is 'Archive of queued messages for incoming TS data - odd months';
comment on column at_ts_msg_archive_1.msg_id          is 'Primary Key';
comment on column at_ts_msg_archive_1.ts_code         is 'TS Code of data';
comment on column at_ts_msg_archive_1.message_time    is 'Message creation time';
comment on column at_ts_msg_archive_1.first_data_time is 'Start of time window of data stored';
comment on column at_ts_msg_archive_1.last_data_time  is 'End of time window of data stored';
-----------------------------
-- AT_TS_MSG_ARCHIVE_1 constraints
--
alter table at_ts_msg_archive_1 add constraint at_ts_msg_archive_1_pk primary key (msg_id)
    using index 
    TABLESPACE CWMS_20AT_DATA
    pctfree    10
    initrans   2
    maxtrans   255
    storage    (
                initial          64k
                minextents       1
                maxextents       2147483645
                pctincrease      0
               );

show errors;
commit;
-----------------------------
-- AT_TS_MSG_ARCHIVE_1 indicies
--
create index at_ts_msg_archive_1_ndx1 on at_ts_msg_archive_1
(message_time, ts_code)
logging
TABLESPACE CWMS_20AT_DATA
pctfree    10
initrans   2
maxtrans   255
storage    (
            initial          64k
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
noparallel;
commit;

-----------------------------
-- AT_TS_MSG_ARCHIVE_2 table
--
create table at_ts_msg_archive_2
(
   msg_id          varchar2(32)  not null,
   ts_code         number(10)    not null,
   message_time    timestamp(6)  not null,
   first_data_time date          not null,
   last_data_time  date          not null
)
TABLESPACE CWMS_20AT_DATA
pctused    0
pctfree    10
initrans   1
maxtrans   255
storage    (
            initial          5m
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
logging 
nocompress 
nocache
noparallel
monitoring;

-----------------------------
-- AT_TS_MSG_ARCHIVE_2 comments
--
comment on table  at_ts_msg_archive_2                 is 'Archive of queued messages for incoming TS data - even months';
comment on column at_ts_msg_archive_2.msg_id          is 'Primary Key';
comment on column at_ts_msg_archive_2.ts_code         is 'TS Code of data';
comment on column at_ts_msg_archive_2.message_time    is 'Message creation time';
comment on column at_ts_msg_archive_2.first_data_time is 'Start of time window of data stored';
comment on column at_ts_msg_archive_2.last_data_time  is 'End of time window of data stored';
-----------------------------
-- AT_TS_MSG_ARCHIVE_2 constraints
--
alter table at_ts_msg_archive_2 add constraint at_ts_msg_archive_2_pk primary key (msg_id)
    using index 
    TABLESPACE CWMS_20AT_DATA
    pctfree    10
    initrans   2
    maxtrans   255
    storage    (
                initial          64k
                minextents       1
                maxextents       2147483645
                pctincrease      0
               );

show errors;
-----------------------------
-- AT_TS_MSG_ARCHIVE_2 indicies
--
create index at_ts_msg_archive_2_ndx1 on at_ts_msg_archive_2
(message_time, ts_code)
logging
TABLESPACE CWMS_20AT_DATA
pctfree    10
initrans   2
maxtrans   255
storage    (
            initial          64k
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
noparallel;
commit;

-----------------------------
-- AT_LOG_MESSAGE table
--
create table at_log_message
(
   msg_id               varchar2(32)                not null,
   office_code          number(10)                  not null,
   log_timestamp_utc    timestamp                   not null,
   msg_level            number(2)                   not null,
   component            varchar2(64)                not null,
   instance             varchar2(64),
   host                 varchar2(256),
   port                 number(5),
   report_timestamp_utc timestamp,
   session_username     varchar2(30),
   session_osuser       varchar2(30),
   session_process      varchar2(24),
   session_program      varchar2(64),
   session_machine      varchar2(64),
   msg_type             number(2),
   msg_text             varchar2(4000)
)
TABLESPACE CWMS_20AT_DATA
pctused    0
pctfree    10
initrans   1
maxtrans   255
storage    (
            initial          5m
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
logging 
nocompress 
nocache
noparallel
monitoring;

-----------------------------
-- AT_LOG_MESSAGE comments
--
comment on table  at_log_message                      is 'CWMS log messages';
comment on column at_log_message.msg_id               is 'Unique ID of message, includes timestamp and sequence';
comment on column at_log_message.office_code          is 'Office code of user';
comment on column at_log_message.log_timestamp_utc    is 'Timestamp of when the message was logged (set by database)';
comment on column at_log_message.msg_level            is 'Detail level of message';
comment on column at_log_message.component            is 'Reporting component';
comment on column at_log_message.instance             is 'Instance of reporting component, if applicable';
comment on column at_log_message.host                 is 'Host on which reporting component is executing';
comment on column at_log_message.port                 is 'Port at which reporting component is contacted, if applicable';
comment on column at_log_message.report_timestamp_utc is 'Timestamp of when the message was reported (set by client)';
comment on column at_log_message.session_username     is 'V$SESSION.USERNAME';
comment on column at_log_message.session_osuser       is 'V$SESSION.OSUSER';
comment on column at_log_message.session_process      is 'V$SESSION.PROCESS';
comment on column at_log_message.session_program      is 'V$SESSION.PROGRAM';
comment on column at_log_message.session_machine      is 'V$SESSION.MACHINE';
comment on column at_log_message.msg_type             is 'Type of message from CWMS_LOG_MESSAGE table';
comment on column at_log_message.msg_text             is 'Main text of message, possibly augmented by properties';

-----------------------------
-- AT_LOG_MESSAGE constraints
--
alter table at_log_message add constraint at_log_message_fk1 foreign key (msg_type) references cwms_log_message_types (message_type_code);
alter table at_log_message add constraint at_log_message_fk2 foreign key (office_code) references cwms_office (office_code);
alter table at_log_message add constraint at_log_message_ck2 check (msg_level between 1 and 7);
alter table at_log_message add constraint at_log_message_pk  primary key (msg_id)
    using index 
    TABLESPACE CWMS_20AT_DATA
    pctfree    10
    initrans   2
    maxtrans   255
    storage    (
                initial          64k
                minextents       1
                maxextents       2147483645
                pctincrease      0
               );

-----------------------------
-- AT_LOG_MESSAGE indicies
--
create index at_log_message_ndx1 on at_log_message
(log_timestamp_utc, msg_level)
logging
TABLESPACE CWMS_20AT_DATA
pctfree    10
initrans   2
maxtrans   255
storage    (
            initial          64k
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
noparallel;
commit;
-----------------------------
-- AT_LOG_MESSAGE_PROPERTIES table
--
create table at_log_message_properties
(
   msg_id            varchar2(32)    not null,
   prop_name         varchar2(64)    not null,
   prop_type         number(1)       not null,
   prop_value        number,
   prop_text         varchar2(4000)
)
storage    (
            initial          5m
            minextents       1
            maxextents       2147483645
            pctincrease      0
            buffer_pool      default
           )
logging 
nocompress 
nocache
noparallel
monitoring;

-----------------------------
-- AT_LOG_MESSAGE_PROPERTIES comments
--
comment on table  at_log_message_properties            is 'Optional properties for CWMS log messages';
comment on column at_log_message_properties.msg_id     is 'Unique ID of message from AT_LOG_MESSAGES';
comment on column at_log_message_properties.prop_name  is 'Property name';
comment on column at_log_message_properties.prop_type  is 'Property type from CWMS_LOG_MESSAGE_PROP_TYPES';
comment on column at_log_message_properties.prop_value is 'Property value if property type is numeric';
comment on column at_log_message_properties.prop_text  is 'Property value if property type is String or boolean';

-----------------------------
-- AT_LOG_MESSAGE_PROPERTIES constraints
--
alter table at_log_message_properties add constraint at_log_message_properties_fk1 foreign key (msg_id) references at_log_message (msg_id);
alter table at_log_message_properties add constraint at_log_message_properties_fk2 foreign key (prop_type) references cwms_log_message_prop_types (prop_type_code);
alter table at_log_message_properties add constraint at_log_message_properties_pk  primary key (msg_id, prop_name)
    using index 
    TABLESPACE CWMS_20AT_DATA
    pctfree    10
    initrans   2
    maxtrans   255
    storage    (
                initial          64k
                minextents       1
                maxextents       2147483645
                pctincrease      0
               );

-----------------------------
-- AT_MVIEW_REFRESH_PAUSED table
--
CREATE TABLE AT_MVIEW_REFRESH_PAUSED
(
  PAUSED_AT   TIMESTAMP(6)                      NOT NULL,
  MVIEW_NAME  VARCHAR2(30 CHAR)                 NOT NULL,
  USER_NAME   VARCHAR2(30 CHAR)                 NOT NULL,
  REMARKS     VARCHAR2(80 CHAR)
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING;
-----------------------------
-- AT_MVIEW_REFRESH_PAUSED comments
--
COMMENT ON TABLE AT_MVIEW_REFRESH_PAUSED IS 'M-views temporarily switched from on commit refresh to on demand';
COMMENT ON COLUMN AT_MVIEW_REFRESH_PAUSED.PAUSED_AT IS 'Timestamp of pause action';
COMMENT ON COLUMN AT_MVIEW_REFRESH_PAUSED.MVIEW_NAME IS 'Name of paused m-view';
COMMENT ON COLUMN AT_MVIEW_REFRESH_PAUSED.USER_NAME IS 'Name of user causing action';
COMMENT ON COLUMN AT_MVIEW_REFRESH_PAUSED.REMARKS IS 'Comment on action';
-----------------------------
-- AT_MVIEW_REFRESH_PAUSED constraints
--
ALTER TABLE AT_MVIEW_REFRESH_PAUSED ADD CONSTRAINT AT_MVIEW_REFRESH_PAUSED_PK PRIMARY KEY(PAUSED_AT, MVIEW_NAME);

show errors;
commit;
