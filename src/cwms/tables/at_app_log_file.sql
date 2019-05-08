create table at_app_log_file(
   log_file_code integer,
	log_dir_code  integer not null,
	log_file_name varchar2(256),
	constraint at_app_log_file_pk  primary key (log_file_code),
	constraint at_app_log_file_fk1 foreign key (log_dir_code) references at_app_log_dir (log_dir_code),
	constraint at_app_log_file_u1  unique (log_dir_code, log_file_name),
	constraint at_app_log_file_ck1 check (not regexp_like(log_file_name, '.+[/\].+'))
)
tablespace cwms_20at_data;

comment on table  at_app_log_file               is 'Holds application log files';
comment on column at_app_log_file.log_file_code is 'Synthetic key for referencing from log file entries';
comment on column at_app_log_file.log_dir_code  is 'Reference to directory of log file';
comment on column at_app_log_file.log_file_name is 'Name of log file in directory';

