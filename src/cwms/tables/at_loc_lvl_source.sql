-- drop table at_loc_lvl_source;
create table at_loc_lvl_source(
   loc_lvl_source_code      integer,
   location_code            integer not null,
   specified_level_code     integer not null,
   parameter_code           integer not null,
   parameter_type_code      integer not null,
   duration_code            integer not null,
   attr_value               number,
   attr_parameter_code      integer,
   attr_parameter_type_code integer,
   attr_duration_code       integer,
   source_entity            integer,
   constraint at_loc_lvl_source_pk  primary key (loc_lvl_source_code),
   constraint at_loc_lvl_source_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_loc_lvl_source_fk2 foreign key (specified_level_code) references at_specified_level (specified_level_code),
   constraint at_loc_lvl_source_fk3 foreign key (parameter_code) references at_parameter (parameter_code),
   constraint at_loc_lvl_source_fk4 foreign key (parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_loc_lvl_source_fk5 foreign key (duration_code) references cwms_duration (duration_code),
   constraint at_loc_lvl_source_fk6 foreign key (attr_parameter_code) references at_parameter (parameter_code),
   constraint at_loc_lvl_source_fk7 foreign key (attr_parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_loc_lvl_source_fk8 foreign key (attr_duration_code) references cwms_duration (duration_code),
   constraint at_loc_lvl_source_fk9 foreign key (source_entity) references at_entity (entity_code)
)
tablespace cwms_20at_data;

comment on table  at_loc_lvl_source                          is 'Holds source entity for location levels';
comment on column at_loc_lvl_source.loc_lvl_source_code      is 'Synthetic key';
comment on column at_loc_lvl_source.location_code            is 'Location of location level';
comment on column at_loc_lvl_source.specified_level_code     is 'Specified level of location level';
comment on column at_loc_lvl_source.parameter_code           is 'Parameter of location level';
comment on column at_loc_lvl_source.parameter_type_code      is 'Parameter type of location level';
comment on column at_loc_lvl_source.duration_code            is 'Duration of location level';
comment on column at_loc_lvl_source.attr_value               is 'Attribute value of location level';
comment on column at_loc_lvl_source.attr_parameter_code      is 'Attribute parameter code of location level';
comment on column at_loc_lvl_source.attr_parameter_type_code is 'Attribute parameter type of location level';
comment on column at_loc_lvl_source.attr_duration_code       is 'Attribute duration of location level';
comment on column at_loc_lvl_source.source_entity            is 'Entity that is the source of the location level';

create unique index at_loc_lvl_source_u1 on at_loc_lvl_source (
      location_code,
      specified_level_code,
      parameter_code,
      parameter_type_code,
      duration_code,
      nvl(attr_value               , -1),
      nvl(attr_parameter_code      , -1),
      nvl(attr_parameter_type_code , -1),
      nvl(attr_duration_code       , -1));

