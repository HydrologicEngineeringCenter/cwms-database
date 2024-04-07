create table at_fcst_info (
   fcst_inst_code  varchar2(36)   not null,
   key             varchar2(256)  not null,
   value           varchar2(4000) not null,
   constraint at_fcst_info_fk1 foreign key (fcst_inst_code) references at_fcst_inst (fcst_inst_code)
) tablespace cwms_20at_data;

create unique index at_fcst_info_pk on at_fcst_info (fcst_inst_code, key, value);
create index at_fcst_info_idx1 on at_fcst_info(key, value);

comment on table at_fcst_info is 'Holds (key, value) pairs for a forecast';
comment on column at_fcst_info.fcst_inst_code is 'References forecast instance';
comment on column at_fcst_info.key            is 'Key name';
comment on column at_fcst_info.value          is 'Value associated with key';
