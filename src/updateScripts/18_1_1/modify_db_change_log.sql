-----------------------------------------------------------------------
-- create a temporary table of the same structure as the current one --
-----------------------------------------------------------------------
create table tmp_db_change_log(
   application varchar2(32), 
	ver_major   number, 
	ver_minor   number, 
	ver_build   number, 
	ver_date    date, 
	apply_date  date, 
	title       varchar2(256 byte), 
	description clob,
	constraint tmp_db_change_log_pk primary key (application, ver_major, ver_minor, ver_build)
);
---------------------------------------------------------
-- populate the temporary table with the existing rows --
---------------------------------------------------------
insert 
  into tmp_db_change_log
select * 
  from cwms_db_change_log;
-----------------------------------------------------------------
-- drop the original table and re-create it with new structure --
-----------------------------------------------------------------
drop table cwms_db_change_log;
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
----------------------------------------------------------------------------
-- re-populate the new table from the previous rows including new columns --
----------------------------------------------------------------------------
insert
  into cwms_db_change_log
select cwms_util.user_office_code,
       nvl(v.primary_db_unique_name, v.db_unique_name),
       l.application,
       l.ver_major,
       l.ver_minor,
       l.ver_build,
       l.ver_date,
       l.apply_date,
       l.title,
       l.description
  from tmp_db_change_log l,
       v$database v;
---------------------------------
-- re-create the table trigger --
---------------------------------
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
---------------------------------------
-- finally, drop the temporary table --
---------------------------------------
drop table tmp_db_change_log;
---------------------------
-- now, rebuild the view --
---------------------------
whenever sqlerror continue;
delete from at_clob where id = '/VIEWDOCS/AV_DB_CHANGE_LOG';
whenever sqlerror exit;
@@../cwms/views/av_db_change_log
