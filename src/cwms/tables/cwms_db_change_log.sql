/* Formatted on 8/25/2015 3:52:32 PM (QP5 v5.269.14213.34769) */
create table cwms_db_change_log
(
   application   varchar2 (32 byte) not null,
   ver_major     number not null,
   ver_minor     number not null,
   ver_build     number not null,
   ver_date      date,
   apply_date    date,
   title         varchar2 (256 byte),
   description   clob
)
lob (description) store as
   (tablespace cwms_20data
    enable storage in row
    chunk 8192
    pctversion 10
    nocache logging
    storage (initial 64 k
             next 1 m
             minextents 1
             maxextents unlimited
             pctincrease 0
             buffer_pool default
             flash_cache default
             cell_flash_cache default))
tablespace cwms_20data
result_cache (mode default)
pctused 0
pctfree 10
initrans 1
maxtrans 255
storage (initial 64 k
         next 1 m
         maxsize unlimited
         minextents 1
         maxextents unlimited
         pctincrease 0
         buffer_pool default
         flash_cache default
         cell_flash_cache default)
logging
nocompress
nocache
noparallel
monitoring
/

create unique index cwms_db_change_log_pk
   on cwms_db_change_log (application,
                          ver_major,
                          ver_minor,
                          ver_build)
   logging
   tablespace cwms_20data
   pctfree 10
   initrans 2
   maxtrans 255
   storage (initial 64 k
            next 1 m
            maxsize unlimited
            minextents 1
            maxextents unlimited
            pctincrease 0
            buffer_pool default
            flash_cache default
            cell_flash_cache default)
   noparallel
/

create or replace trigger cwms_db_change_log_trig01
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


alter table cwms_db_change_log add (
  constraint cwms_db_change_log_pk
  primary key
  (application, ver_major, ver_minor, ver_build)
  using index cwms_db_change_log_pk
  enable validate)
/

insert into cwms_db_change_log (office_code, database_id, application, ver_major, ver_minor, ver_build, ver_date) values(51, 'CWMSDEV', 'CWMS', 18, 1, 0, sysdate);
commit;

