create table at_app_log_dir(
   log_dir_code integer, 
	office_code  integer, 
	host_fqdn    varchar2(128) not null,
	log_dir_name varchar2(256) not null,
	constraint at_app_log_dir_pk  primary key (log_dir_code),  
	constraint at_app_log_dir_ck1 check (regexp_like(host_fqdn, '^(([[:alnum:]][[:alnum:]-]{0,61}[[:alnum:]])\.)+[[:alnum:]][[:alnum:]-]{0,61}[[:alnum:]]$')),
	constraint at_app_log_dir_ck2 check (not regexp_like(host_fqdn, '^(([[:digit:]]+)[.])+[[:digit:]]+$')),
	constraint at_app_log_dir_ck3 check (instr(log_dir_name, '/') = 1 or regexp_instr(log_dir_name, '[[:alpha:]]:\\') = 1),
	constraint at_app_log_dir_ck4 check (instr(log_dir_name, '/') = 0 or instr(log_dir_name, '\') = 0),
	constraint at_app_log_dir_ck5 check (not regexp_like(log_dir_name, '[/\]\.')),
	constraint at_app_log_dir_ck6 check (not regexp_like(log_dir_name, '.+[/\]$'))  
)
tablespace cwms_20at_data;

comment on table  at_app_log_dir              is 'Holds directories for application log files';
comment on column at_app_log_dir.log_dir_code is 'Synthetic key for referncing from log files';
comment on column at_app_log_dir.office_code  is 'Office that owns host containing log dir';
comment on column at_app_log_dir.host_fqdn    is 'Fully qualified domain name of host in lower case';
comment on column at_app_log_dir.log_dir_name is 'Absolute pathname of log directory on host';

create or replace trigger at_app_log_dir_t01 
before insert
       or update of host_fqdn
       on at_app_log_dir
       for each row
declare
begin
   :new.host_fqdn := lower(:new.host_fqdn);
end at_app_log_dir_t01;
/

