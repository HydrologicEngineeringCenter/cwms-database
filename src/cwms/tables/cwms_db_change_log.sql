create table cwms_db_change_log(
   office_code integer,
   database_id varchar2(30),
   application varchar2(32), 
	ver_major   integer, 
	ver_minor   integer, 
   ver_build   integer,
	ver_date    date, 
	apply_date  date, 
	title       varchar2(256 byte), 
	description clob,
	constraint cwms_db_change_log_pk primary key (office_code, database_id, application, ver_major, ver_minor, ver_build) using index,
   constraint cwms_db_change_log_fk foreign key (office_code) references cwms_office (office_code)
)
tablespace cwms_20data;

create trigger cwms_db_change_log_trig01
   before insert or
          update of ver_major,
                    ver_minor,
                    ver_build,
                    ver_date,
                    title
   on "CWMS_DB_CHANGE_LOG"
   referencing new as new old as old
   for each row
declare
begin
   :new.apply_date := sysdate;
end;
/

insert into cwms_db_change_log (office_code, database_id, application, ver_major, ver_minor, ver_build, ver_date) values(51, 'CWMSDEV', 'CWMS', 99, 1, 0, sysdate);
commit;

