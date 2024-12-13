create table at_fcst_inst (
   fcst_inst_code    varchar2(36) not null,
   fcst_spec_code    varchar2(36) not null,
   fcst_date_time    date         not null,
   issue_date_time   date         not null,
   max_age           number(6),
   notes             varchar2(256),
   blob_file         blob_file_t,
   constraint at_fcst_inst_pk  primary key (fcst_inst_code),
   constraint at_fcst_inst_fk1 foreign key (fcst_spec_code) references at_fcst_spec (fcst_spec_code)
) tablespace cwms_20at_data;

create unique index at_fcst_inst_idx1 on at_fcst_inst (fcst_spec_code, fcst_date_time, issue_date_time);
create index at_fcst_inst_idx2 on at_fcst_inst (issue_date_time, fcst_spec_code);

comment on table at_fcst_inst is 'Holds information on forecast instances';
comment on column at_fcst_inst.fcst_inst_code    is 'Unique key - UUID';
comment on column at_fcst_inst.fcst_spec_code    is 'References forecast specification';
comment on column at_fcst_inst.fcst_date_time    is 'The date/time the forecast is for';
comment on column at_fcst_inst.issue_date_time   is 'The date/time the forecast was issued (also version date of any time series stored)';
comment on column at_fcst_inst.max_age           is 'The number of hours from the issue date/time that the forecast is considered valid';
comment on column at_fcst_inst.notes             is 'Notes about this forecast';
