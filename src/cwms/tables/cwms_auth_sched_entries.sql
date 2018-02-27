create table cwms_auth_sched_entries(	
   database_name   varchar2(30), 
   job_owner       varchar2(30),
	job_name        varchar2(30),   
	job_creator     varchar2(30),   
	job_style       varchar2(11),   
	job_type        varchar2(16),   
	job_priority    number,         
	schedule_type   varchar2(12),   
	repeat_interval varchar2(4000), 
	comments        varchar2(240),  
	job_action      varchar2(4000),
	constraint cwms_auth_sched_entries_pk primary key (database_name, job_owner, job_name) using index
)  tablespace cwms_20data;

comment on table  cwms_auth_sched_entries                 is 'Holds expected scheduler entries for this database';
comment on column cwms_auth_sched_entries.database_name   is 'SID of prmimary database, or ''CWMS'' for all databases';
comment on column cwms_auth_sched_entries.job_owner       is '''OWNER'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_name        is '''JOB_NAME'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_creator     is '''JOB_CREATOR'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_style       is '''JOB_STYLE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_type        is '''JOB_TYPE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_priority    is '''JOB_PRIORITY'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.schedule_type   is '''SCHEDULE_TYPE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.repeat_interval is '''REPEAT_INTERVAL'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.comments        is '''COMMENTS'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_auth_sched_entries.job_action      is '''JOB_ACTION'' column from DBA_SCHEDULER_JOBS';

create or replace trigger cwms_auth_sched_entries_t01
before insert or update
       of database_name,
          job_owner,
          job_name
       on cwms_auth_sched_entries
       for each row
declare
begin
   :new.database_name := upper(:new.database_name);
   :new.job_owner     := upper(:new.job_owner);
   :new.job_name      := upper(:new.job_name);
end cwms_auth_sched_entries_t01;
/
show errors

insert 
  into cwms_auth_sched_entries 
values ('CWMS',
        'CWMS_20',
        'CLEAN_SESSION_KEYS_JOB',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=minutely; interval=1',
        'Clean expired session keys',
        'cwms_sec.clean_session_keys');
insert
  into CWMS_auth_sched_entries 
values ('CWMS',
        'CWMS_20',
        'REMOVE_STATUS_SUBSCRIBERS',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=daily; interval=1',
        'Delete status queue subscribers that are more than one day old',
        'cwms_20.REMOVE_SUBSCRIBERS');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_20',
        'UPDATE_SHEF_SPEC_MAPPING',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',                                             
        3,
        'CALENDAR',
        'freq=minutely; interval=1',
        'Updates Shef Crit File Mappings when needed.',
        'cwms_shef.update_shef_spec_mapping');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_20',
        'TRIM_TS_DELETED_TIMES_JOB',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=minutely; interval=15',
        'Trims at_ts_deleted_times to specified max entries and max age.',
        'cwms_ts.trim_ts_deleted_times');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_20',
        'PURGE_QUEUES_JOB',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=minutely; interval=5',
        'Purges expired and undeliverable messages from queues.',
        'cwms_msg.purge_queues');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_20',
        'TRIM_LOG_JOB',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=minutely; interval=240',
        'Trims at_log_message to specified max entries and max age.',
        'cwms_msg.trim_log');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_STR_ADM',
        'STREAMS_RESTART_PROP_JOB',
        'CWMS_STR_ADM',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=MINUTELY; interval=30',
        'Check apply/capture',
        'util.restart_propagation');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_STR_ADM',
        'STREAMS_CHECK_CAPTURE_JOB',                                                                
        'CWMS_STR_ADM',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=MINUTELY; interval=5',
        'Check apply/capture',
        'util.check_capture');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_STR_ADM',
        'MV_TS_REFRESH_JOB',
        'CWMS_STR_ADM',
        'REGULAR',
        'PLSQL_BLOCK',
        3,
        'CALENDAR',
        'freq=secondly; interval=3600',
        'REFRESH TS CODE FILTER TABLE',
        'BEGIN DBMS_MVIEW.REFRESH(''MV_TS_CODE_FILTER''); END;');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CWMS_STR_ADM',
        'STREAMS_HEARTBEAT_JOB',
        'CWMS_STR_ADM',
        'REGULAR',
        'PLSQL_BLOCK',
        3,
        'CALENDAR',
        'freq=secondly; interval=60',
        'Update hearbeat table',
        'BEGIN util.update_heartbeat; END;');
insert
  into CWMS_auth_sched_entries
values ('CWMS',
        'CCP',
        'CHECK_NOTIFY_CALLBACK_PROC_JOB',
        'CCP',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=minutely; interval= 15',
        'check if the subscriber for callback_proc exists.',
        'cwms_ccp.check_callback_proc_subscriber');
insert
  into cwms_auth_sched_entries
values ('CWMS',
        'CWMS_20',
        'MONITOR_SCHEDULER_JOBS',
        'CWMS_20',
        'REGULAR',
        'STORED_PROCEDURE',
        3,
        'CALENDAR',
        'freq=daily; interval=1',
        'Monitors scheduler for unauthorized entries',
        'cwms_scheduler_auth.check_scheduler_entries');
