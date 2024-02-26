create table at_fcst_file (
   fcst_inst_code number(14)   not null,
   blob_code      number(14)   not null,
   file_name      varchar2(64) not null,
   description    varchar2(64),
   constraint at_fcst_file_fk1 foreign key (fcst_inst_code) references at_fcst_inst (fcst_inst_code),
   constraint at_fcst_file_fk2 foreign key (blob_code) references at_blob (blob_code)
) tablespace cwms_20at_data;

create unique index at_fcst_file_pk on at_fcst_file (fcst_inst_code, blob_code);
create unique index at_fcst_file_idx1 on at_fcst_file (fcst_inst_code, upper(file_name));

comment on table at_fcst_file is 'Holds information on forecast files';
comment on column at_fcst_file.fcst_inst_code is 'References forecast instance';
comment on column at_fcst_file.blob_code      is 'References file BLOB';
comment on column at_fcst_file.file_name      is 'Base name of file (no directories) - must include file extension';
comment on column at_fcst_file.description    is 'Description of file contents';
