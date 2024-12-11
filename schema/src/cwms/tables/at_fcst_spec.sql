create table at_fcst_spec (
   fcst_spec_code  varchar2(36)  not null,
   office_code     number(14)    not null,
   fcst_spec_id    varchar2(256) not null,
   fcst_designator varchar2(256),
   source_entity   number(14)    not null,
   description     varchar2(256),
   constraint at_fsct_spec_pk  primary key (fcst_spec_code),
   constraint at_fcst_spec_fk1 foreign key (office_code) references cwms_office (office_code),
   constraint at_fcst_spec_fk2 foreign key (source_entity) references at_entity (entity_code)
) tablespace cwms_20at_data;

create unique index at_fcst_spec_idx1 on at_fcst_spec (office_code, upper(fcst_spec_id), upper(nvl(fcst_designator, '~')));
-- can't do the following until the package specs are compiled
-- create unique index at_fcst_spec_idx2 on at_fcst_spec (cwms_util.get_db_office_id_from_code(office_code), fcst_spec_id, fcst_designator); 
create index at_fcst_spec_idx3 on at_fcst_spec (upper(fcst_spec_id), upper(nvl(fcst_designator, '~')));

comment on table at_fcst_spec is 'Holds information on forecast specfications';
comment on column at_fcst_spec.fcst_spec_code  is 'Unique key - UUID';
comment on column at_fcst_spec.office_code     is 'References office that owns specification';
comment on column at_fcst_spec.fcst_spec_id    is '"Main name" of forecast specification';
comment on column at_fcst_spec.fcst_designator is '"Sub-name" of forecast specification, if any';
comment on column at_fcst_spec.source_entity   is 'References entity that generates forecasts';
comment on column at_fcst_spec.description     is 'Description of forecasts of this specfication';
