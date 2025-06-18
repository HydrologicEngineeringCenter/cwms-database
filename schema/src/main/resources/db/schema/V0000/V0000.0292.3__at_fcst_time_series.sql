create table at_fcst_time_series (
   fcst_spec_code  varchar2(36) not null,
   ts_code         number(14)   not null,
   constraint at_fcst_time_series_fk1 foreign key (fcst_spec_code) references at_fcst_spec (fcst_spec_code),
   constraint at_fcst_time_series_fk2 foreign key (ts_code) references at_cwms_ts_spec (ts_code)
) tablespace cwms_20at_data;

create unique index at_fcst_time_series_pk on at_fcst_time_series (fcst_spec_code, ts_code);
create unique index at_fcst_time_series_idx1 on at_fcst_time_series (ts_code, fcst_spec_code);

comment on table at_fcst_time_series is 'Holds information on forecast time series';
comment on column at_fcst_time_series.fcst_spec_code  is 'References forecast specification';
comment on column at_fcst_time_series.ts_code         is 'References time series';
