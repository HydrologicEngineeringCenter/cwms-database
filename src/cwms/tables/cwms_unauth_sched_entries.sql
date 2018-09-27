create table cwms_unauth_sched_entries (
   database_name   varchar2(30), 
   job_owner       varchar2(30),
   job_name        varchar2(30),
   first_detected  date,
   job_creator     varchar2(30),   
   job_style       varchar2(11),   
   job_type        varchar2(16),   
   job_priority    number,         
   schedule_type   varchar2(12),   
   repeat_interval varchar2(4000), 
   comments        varchar2(240),  
   job_action      varchar2(4000),
   constraint cwms_unauth_sched_entries_pk primary key (database_name, job_owner, job_name) using index
)  tablespace cwms_20data;

comment on table  cwms_unauth_sched_entries                 is 'Holds detected unauthorized scheduler entries for this database';
comment on column cwms_unauth_sched_entries.database_name   is 'SID of prmimary database';
comment on column cwms_unauth_sched_entries.job_owner       is '''OWNER'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.job_name        is '''JOB_NAME'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.first_detected  is 'Date/time the unathorized scheduler entry was detected';
comment on column cwms_unauth_sched_entries.job_creator     is '''JOB_CREATOR'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.job_style       is '''JOB_STYLE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.job_type        is '''JOB_TYPE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.job_priority    is '''JOB_PRIORITY'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.schedule_type   is '''SCHEDULE_TYPE'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.repeat_interval is '''REPEAT_INTERVAL'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.comments        is '''COMMENTS'' column from DBA_SCHEDULER_JOBS';
comment on column cwms_unauth_sched_entries.job_action      is '''JOB_ACTION'' column from DBA_SCHEDULER_JOBS';

create or replace trigger cwms_unauth_sched_entries_t01
before insert or update
       of database_name,
          job_owner,
          job_name
       on cwms_unauth_sched_entries
       for each row
declare
begin
   :new.database_name := upper(:new.database_name);
   :new.job_owner     := upper(:new.job_owner);
   :new.job_name      := upper(:new.job_name);
end cwms_unauth_sched_entries_t01;
/

