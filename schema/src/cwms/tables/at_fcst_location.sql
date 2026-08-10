create table at_fcst_location (
   fcst_spec_code varchar2(36) not null,
   location_code  number(14)   not null,
   sort_order     number       not null,
   constraint at_fcst_location_pk primary key (fcst_spec_code, location_code) using index,
   constraint at_fcst_location_fk1 foreign key (fcst_spec_code) references at_fcst_spec (fcst_spec_code),
   constraint at_fcst_location_fk2 foreign key (location_code) references at_physical_location (location_code)
) tablespace cwms_20at_data;

create unique index at_fcst_location_idx1 on at_fcst_location (location_code, fcst_spec_code);

create unique index at_fcst_location_idx2 
on at_fcst_location (
  case when sort_order = -1 then fcst_spec_code end,
  case when sort_order = -1 then sort_order end
);

comment on table at_fcst_location is 'Holds information on locations for forecasts';
comment on column at_fcst_location.fcst_spec_code is 'References forecast specification';
comment on column at_fcst_location.location_code  is 'References location for forecast';
comment on column at_fcst_location.sort_order     is 'The sort order of the location for the forecast. -1 means primary.';
