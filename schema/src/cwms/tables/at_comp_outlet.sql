create table at_comp_outlet(
   compound_outlet_code  number(14)   primary key,
   project_location_code number(14)   not null,
   compound_outlet_id    varchar2(64) not null,
   constraint at_comp_outlet_fk1 foreign key (project_location_code) references at_project (project_location_code),
   constraint at_comp_outlet_ck1 check (trim(compound_outlet_id) = compound_outlet_id)
) organization index
  tablespace cwms_20at_data
;

comment on table  at_comp_outlet is 'Holds information about sequential outlet groups';
comment on column at_comp_outlet.compound_outlet_code  is 'Synthetic key';
comment on column at_comp_outlet.project_location_code is 'References project that has this compound outlet';
comment on column at_comp_outlet.compound_outlet_id    is 'Name of this compound outlet (unique per project)';

create unique index at_comp_outlet_idx1 on at_comp_outlet (project_location_code, upper(compound_outlet_id))
/
