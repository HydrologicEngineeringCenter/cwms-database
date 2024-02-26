create table at_fcst_spec (
   fcst_spec_code number(14)   not null,
   office_code    number(14)   not null,
   fcst_spec_id   varchar2(32) not null,
   location_code  number(14)   not null,
   source_entity  number(14)   not null,
   description    varchar2(64),
   constraint at_fsct_spec_pk  primary key (fcst_spec_code),
   constraint at_fcst_spec_fk1 foreign key (office_code) references cwms_office (office_code),
   constraint at_fcst_spec_fk2 foreign key (location_code) references at_physical_location (location_code),
   constraint at_fcst_spec_fk3 foreign key (source_entity) references at_entity (entity_code),
   constraint at_fcst_spec_ck1 check (fcst_spec_id = upper(fcst_spec_id))
) tablespace cwms_20at_data;

create unique index at_fcst_spec_idx1 on at_fcst_spec (office_code, fcst_spec_id, location_code);
create index at_fcst_spec_idx2 on at_fcst_spec (location_code, fcst_spec_id);

comment on table at_fcst_spec is 'Holds information on forecast specfications';
comment on column at_fcst_spec.fcst_spec_code is 'Unique key';
comment on column at_fcst_spec.office_code    is 'References office that owns specification';
comment on column at_fcst_spec.fcst_spec_id   is 'Name of forecast specification (e.g. ''CAVI'', ''RVF'')';
comment on column at_fcst_spec.location_code  is 'References location that forecasts are for';
comment on column at_fcst_spec.source_entity  is 'References entity that generates forecasts';
comment on column at_fcst_spec.description    is 'Description of forecasts of this specfication';
