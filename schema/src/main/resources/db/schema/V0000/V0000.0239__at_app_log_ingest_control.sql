create table at_app_log_ingest_control (
   log_dir_code          integer,
	ingest_file_name_mask varchar2(256) default '*',
	ingest_sub_dirs       varchar2(1)   default 'F',
	max_entry_age         varchar2(16)  default 'P1M',
	max_file_size         integer       default 50 * 1024 * 1024, -- 50 MB
	delete_empty_files    varchar2(1)   default 'T',
   constraint at_app_log_ingest_control_pk primary key (log_dir_code, ingest_file_name_mask),
   constraint at_app_log_ingest_control_fk1 foreign key (log_dir_code) references at_app_log_dir (log_dir_code)
)
tablespace cwms_20at_data;

comment on table  at_app_log_ingest_control                       is 'Holds control information for log ingest application and internal table maintenance';
comment on column at_app_log_ingest_control.log_dir_code          is 'Reference to log file directory';
comment on column at_app_log_ingest_control.ingest_file_name_mask is 'File name mask of log files to ingest (glob-style)';
comment on column at_app_log_ingest_control.ingest_sub_dirs       is 'Flag (T/F) specifying whether to ingest log files from sub-directoies';
comment on column at_app_log_ingest_control.max_entry_age         is 'The age after which log entries will be deleted, in iso 8601 duration format';
comment on column at_app_log_ingest_control.max_file_size         is 'The size after which the oldest entries for a file will be deleted';
comment on column at_app_log_ingest_control.delete_empty_files    is 'Flag (T/F) specifying whether to delete files whose entries have all been deleted. files will be deleted from app_log_file only, not from file system.';
