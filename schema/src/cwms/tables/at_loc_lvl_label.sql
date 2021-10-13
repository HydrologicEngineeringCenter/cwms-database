-- drop table at_loc_lvl_label;
create table at_loc_lvl_label(
   loc_lvl_label_code       integer,
   location_code            integer not null,
   specified_level_code     integer not null,
   parameter_code           integer not null,
   parameter_type_code      integer not null,
   duration_code            integer not null,
   attr_value               number,
   attr_parameter_code      integer,
   attr_parameter_type_code integer,
   attr_duration_code       integer,
   configuration_code       integer not null,
   label                    varchar2(32),
   constraint at_loc_lvl_label_pk  primary key (loc_lvl_label_code),
   constraint at_loc_lvl_label_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_loc_lvl_label_fk2 foreign key (specified_level_code) references at_specified_level (specified_level_code),
   constraint at_loc_lvl_label_fk3 foreign key (parameter_code) references at_parameter (parameter_code),
   constraint at_loc_lvl_label_fk4 foreign key (parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_loc_lvl_label_fk5 foreign key (duration_code) references cwms_duration (duration_code),
   constraint at_loc_lvl_label_fk6 foreign key (attr_parameter_code) references at_parameter (parameter_code),
   constraint at_loc_lvl_label_fk7 foreign key (attr_parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_loc_lvl_label_fk8 foreign key (attr_duration_code) references cwms_duration (duration_code),
   constraint at_loc_lvl_label_fk9 foreign key (configuration_code) references at_configuration (configuration_code)
)
tablespace cwms_20at_data;

comment on table  at_loc_lvl_label                          is 'Holds configuration-specific labels for location levels';
comment on column at_loc_lvl_label.loc_lvl_label_code       is 'Synthetic key';
comment on column at_loc_lvl_label.location_code            is 'Location of location level';
comment on column at_loc_lvl_label.specified_level_code     is 'Specified level of location level';
comment on column at_loc_lvl_label.parameter_code           is 'Parameter of location level';
comment on column at_loc_lvl_label.parameter_type_code      is 'Parameter type of location level';
comment on column at_loc_lvl_label.duration_code            is 'Duration of location level';
comment on column at_loc_lvl_label.attr_value               is 'Attribute value of location level';
comment on column at_loc_lvl_label.attr_parameter_code      is 'Attribute parameter code of location level';
comment on column at_loc_lvl_label.attr_parameter_type_code is 'Attribute parameter type of location level';
comment on column at_loc_lvl_label.attr_duration_code       is 'Attribute duration of location level';
comment on column at_loc_lvl_label.configuration_code       is 'Configuration label is associated with';
comment on column at_loc_lvl_label.label                    is 'Location level label';

create unique index at_loc_lvl_label_u1 on at_loc_lvl_label (
      location_code,
      specified_level_code,
      parameter_code,
      parameter_type_code,
      duration_code,
      nvl(attr_value               , -1),
      nvl(attr_parameter_code      , -1),
      nvl(attr_parameter_type_code , -1),
      nvl(attr_duration_code       , -1),
      configuration_code);

