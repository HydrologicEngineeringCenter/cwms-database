create table at_app_log_entry (
   log_file_code         integer, 
	log_entry_utc         timestamp, 
	log_file_start_offset integer not null,
	log_file_end_offset   integer not null,
	log_entry_text        clob, 
   constraint at_app_log_entry_pk  primary key (log_file_code, log_entry_utc),
	constraint at_app_log_entry_ck1 check (log_file_end_offset >= log_file_start_offset),
	constraint at_app_log_entry_u1  unique (log_file_code, log_file_start_offset),
	constraint at_app_log_entry_u2  unique (log_file_code, log_file_end_offset),
	constraint at_app_log_entry_fk1 foreign key (log_file_code) references at_app_log_file (log_file_code) 
)
tablespace cwms_20at_data;

comment on table  at_app_log_entry                       is 'Holds application log file entries';
comment on column at_app_log_entry.log_file_code         is 'Reference to log file';
comment on column at_app_log_entry.log_entry_utc         is 'Timestamp of when entry was stored';
comment on column at_app_log_entry.log_file_start_offset is 'Offset in log file of first byte of entry';
comment on column at_app_log_entry.log_file_end_offset   is 'Offset in log file of last byte of entry (start + length - 1)';
comment on column at_app_log_entry.log_entry_text        is 'The text of the entry';

create index at_app_log_entry_idx1 on at_app_log_entry (log_entry_utc);

