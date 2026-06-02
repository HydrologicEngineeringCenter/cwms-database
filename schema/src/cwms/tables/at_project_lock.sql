create table at_project_lock (
   lock_id         varchar2(64) primary key,
   project_code    number(14),
   application_id  varchar2(64),
   acquire_time    timestamp,
   session_user    VARCHAR2(128),
   os_user         VARCHAR2(128),
   session_program varchar2(64),
   session_machine varchar2(64),
   constraint at_project_lock_ck1 check (application_id = lower(application_id)),
   constraint at_project_lock_u1  unique (project_code, application_id) using index,
   constraint at_project_lock_fk1 foreign key (project_code) references at_project (project_location_code)
)
tablespace cwms_20at_data
/

comment on table at_project_lock is 'Contains information on projects locked for various applications';
comment on column at_project_lock.lock_id         is 'Unique lock identifier';
comment on column at_project_lock.project_code    is 'References project that is locked for application';
comment on column at_project_lock.application_id  is 'Specifies the application the project is locked for';
comment on column at_project_lock.acquire_time    is 'The UTC time the project lock was acquired';
comment on column at_project_lock.session_user    is 'The session user that acquired the lock';
comment on column at_project_lock.os_user         is 'The session user''s operating system user name';
comment on column at_project_lock.session_program is 'The program that acquired the lock';
comment on column at_project_lock.session_machine is 'The computer that acquired the lock';
