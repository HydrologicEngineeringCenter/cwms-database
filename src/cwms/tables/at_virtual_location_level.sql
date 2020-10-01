create table at_virtual_location_level (
   location_level_code           number(14,0)  not null,
   location_code                 number(14,0)  not null,
   specified_level_code          number(14,0)  not null,
   parameter_code                number(14,0)  not null,
   parameter_type_code           number(14,0)  not null,
   duration_code                 number(14,0)  not null,
   effective_date                date          not null,
   attribute_value               number,
   attribute_parameter_code      number(14,0),
   attribute_parameter_type_code number(14,0),
   attribute_duration_code       number(14,0),
   expiration_date               date,
   constituent_connections       varchar2(256) not null,
   location_level_comment        varchar2(256),
   attribute_comment             varchar2(256),
   constraint at_virtual_location_level_pk  primary key (location_level_code) using index,
   constraint at_virtual_location_level_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_virtual_location_level_fk2 foreign key (specified_level_code) references at_specified_level (specified_level_code),
   constraint at_virtual_location_level_fk3 foreign key (parameter_code) references at_parameter (parameter_code),
   constraint at_virtual_location_level_fk4 foreign key (parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_virtual_location_level_fk5 foreign key (duration_code) references cwms_duration (duration_code),
   constraint at_virtual_location_level_fk6 foreign key (attribute_parameter_code) references at_parameter (parameter_code),
   constraint at_virtual_location_level_fk7 foreign key (attribute_parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_virtual_location_level_fk8 foreign key (attribute_duration_code) references cwms_duration (duration_code)
);

comment on column at_virtual_location_level.location_level_code            is 'Primary key that relates location levels to other entities.';
comment on column at_virtual_location_level.location_code                  is 'References a location.';
comment on column at_virtual_location_level.specified_level_code           is 'References a specified level.';
comment on column at_virtual_location_level.parameter_code                 is 'References the parameter for the level value.';
comment on column at_virtual_location_level.parameter_type_code            is 'References parameter type.';
comment on column at_virtual_location_level.duration_code                  is 'References duration.';
comment on column at_virtual_location_level.effective_date                 is 'Date/time at which this level becomes effective';
comment on column at_virtual_location_level.attribute_value                is 'Value of attribute that constrains applicability of this level.';
comment on column at_virtual_location_level.attribute_parameter_code       is 'References the parameter for the attribute value.';
comment on column at_virtual_location_level.attribute_parameter_type_code  is 'References parameter type for the attribute value.';
comment on column at_virtual_location_level.attribute_duration_code        is 'References duration for the attribute value.';
comment on column at_virtual_location_level.expiration_date                is 'Date/time at which this level expires';
comment on column at_virtual_location_level.constituent_connections        is 'Describes how to combine constituents for result';
comment on column at_virtual_location_level.location_level_comment         is 'Optional comment/description of the level.';
comment on column at_virtual_location_level.attribute_comment              is 'Optional comment/description of the attribute.';

create index at_virtual_location_level_idx1
    on at_virtual_location_level(location_code, specified_level_code, parameter_code, parameter_type_code, duration_code, effective_date);
commit;
