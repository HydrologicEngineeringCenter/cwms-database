create table at_fcst_location (
   fcst_spec_code        varchar2(36) not null,
   primary_location_code number(14)   not null,
   constraint at_fcst_location_pk primary key (fcst_spec_code, primary_location_code) using index,
   constraint at_fcst_location_fk1 foreign key (fcst_spec_code) references at_fcst_spec (fcst_spec_code),
   constraint at_fcst_location_fk2 foreign key (primary_location_code) references at_physical_location (location_code)
) tablespace cwms_20at_data;

create unique index at_fcst_location_idx1 on at_fcst_location (primary_location_code, fcst_spec_code);

comment on table at_fcst_location is 'Holds information on primary locations for forecasts';
comment on column at_fcst_location.fcst_spec_code is 'References forecast specification';
comment on column at_fcst_location.primary_location_code  is 'References primary location for forecast';
