create table at_application_login (
   uuid          varchar2(32)  not null,
   office_code   integer       not null,
   user_name     varchar2(32)  not null,
   app_name      varchar2(64)  not null,
   host_name     varchar2(64)  not null,
   login_time    integer       not null,
   logout_time   integer       default 0, -- used to index searches in cwms_util.logout_dead_app_logins
   normal_logout varchar2(1),
   login_server  varchar2(128) not null,
   constraint at_application_login_pk  primary key (uuid) using index,
   constraint at_application_login_ck1 check ((logout_time is null and normal_logout is null) or normal_logout in ('T', 'F')),
   constraint at_application_login_fk1 foreign key (office_code) references cwms_office (office_code)
) tablespace cwms_20data;

create index at_application_login_idx1 on at_application_login(login_time);
create index at_application_login_idx2 on at_application_login(office_code, user_name, app_name);
create index at_application_login_idx3 on at_application_login(logout_time);

comment on table  at_application_login is 'Holds information about user application login/logoff events';
comment on column at_application_login.uuid          is 'Unique application session identifier';
comment on column at_application_login.office_code   is 'Office code for user running the application';
comment on column at_application_login.user_name     is 'User running the application';
comment on column at_application_login.app_name      is 'Name of the application';
comment on column at_application_login.host_name     is 'Name of system user is running the application on';
comment on column at_application_login.login_time    is 'The time the application logged in, in milliseconds since 01Jan1970 00:00:00 UTC';
comment on column at_application_login.logout_time   is 'The time the application logged out or was found to be disconnected, in milliseconds since 01Jan1970 00:00:00 UTC';
comment on column at_application_login.normal_logout is '''T'' if application logged out, ''F'' if its session was found to be disconnected';
comment on column at_application_login.login_server  is 'The URL of the login server handling the login or logout';
