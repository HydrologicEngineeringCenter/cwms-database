------------------------
-- AT_RATING_TEMPLATE --
------------------------
create table at_rating_template
(
   template_code        number(10),
   office_code          number(10),
   parameters_id        varchar(256),
   version              varchar2(32),
   dep_parameter_code   number(10),
   description          varchar2(256),
   constraint at_rating_template_pk  primary key (template_code),
   constraint at_rating_template_fk1 foreign key (office_code) references cwms_office(office_code),
   constraint at_rating_template_fk2 foreign key (dep_parameter_code) references at_parameter(parameter_code)
) organization index;
create unique index at_rating_template_u1 on at_rating_template(office_code, upper(parameters_id), upper(version));

comment on table  at_rating_template                      is 'Templates for rating tables';
comment on column at_rating_template.template_code        is 'Synthetic key';
comment on column at_rating_template.office_code          is 'Reference to office';
comment on column at_rating_template.parameters_id        is 'Concatenation of parameters utilized and version in form ind1[,ind2[,..]];dep.version';
comment on column at_rating_template.version              is 'Version label, for different rating methods, etc...';
comment on column at_rating_template.dep_parameter_code   is 'Reference to parameter';
comment on column at_rating_template.description          is 'Text description of template';

------------------------------
-- AT_RATING_IND_PARAM_SPEC --
------------------------------
create table at_rating_ind_param_spec
(
   ind_param_spec_code          number(10),
   template_code                number(10) not null,
   parameter_position           number(1)  not null,
   parameter_code               number(10) not null,
   in_range_rating_method       number(10) not null,
   out_range_low_rating_method  number(10) not null,
   out_range_high_rating_method number(10) not null,
   constraint at_rating_ind_param_spec_pk  primary key (ind_param_spec_code),
   constraint at_rating_ind_param_spec_u1  unique (template_code, parameter_position) using index,
   constraint at_rating_ind_param_spec_fk1 foreign key (template_code) references at_rating_template(template_code),
   constraint at_rating_ind_param_spec_fk2 foreign key (parameter_code) references at_parameter(parameter_code),
   constraint at_rating_ind_param_spec_fk3 foreign key (in_range_rating_method) references cwms_rating_method(rating_method_code),
   constraint at_rating_ind_param_spec_fk4 foreign key (out_range_low_rating_method) references cwms_rating_method(rating_method_code),
   constraint at_rating_ind_param_spec_fk5 foreign key (out_range_high_rating_method) references cwms_rating_method(rating_method_code)
) organization index;

comment on table  at_rating_ind_param_spec                              is 'Independent parameters for rating templates';
comment on column at_rating_ind_param_spec.template_code                is 'Reference to rating template';
comment on column at_rating_ind_param_spec.parameter_code               is 'Reference to parameter';
comment on column at_rating_ind_param_spec.parameter_position           is 'Ordinal position of independent parameter in rating';
comment on column at_rating_ind_param_spec.in_range_rating_method       is 'Reference to in-range rating method for the indpendent parameter';
comment on column at_rating_ind_param_spec.out_range_low_rating_method  is 'Reference to low out-of-range rating method for the indpendent parameter';
comment on column at_rating_ind_param_spec.out_range_high_rating_method is 'Reference to high out-of-range rating method for the indpendent parameter';

--------------------
-- AT_RATING_SPEC --
--------------------
create table at_rating_spec
(
   rating_spec_code             number(10),
   template_code                number(10),
   location_code                number(10),
   version                      varchar2(32),
   source_agency_code           number(10),
   in_range_rating_method       number(10)   not null,
   out_range_low_rating_method  number(10)   not null,
   out_range_high_rating_method number(10)   not null,
   active_flag                  varchar2(1)  not null,
   auto_update_flag             varchar2(1)  not null,
   auto_activate_flag           varchar2(1)  not null,
   auto_migrate_ext_flag        varchar2(1)  not null,
   dep_rounding_spec            varchar2(10),
   description                  varchar2(256),
   constraint at_rating_spec_pk  primary key (rating_spec_code),
   constraint at_rating_spec_fk1 foreign key (template_code) references at_rating_template (template_code),
   constraint at_rating_spec_fk2 foreign key (location_code) references at_physical_location (location_code),
   constraint at_rating_spec_fk3 foreign key (source_agency_code) references at_loc_group (loc_group_code), 
   constraint at_rating_spec_fk4 foreign key (in_range_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_fk5 foreign key (out_range_low_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_fk6 foreign key (out_range_high_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_ck1 check (active_flag in ('T', 'F')),
   constraint at_rating_spec_ck2 check (auto_update_flag in ('T', 'F')),
   constraint at_rating_spec_ck3 check (auto_activate_flag in ('T', 'F')),
   constraint at_rating_spec_ck4 check (auto_migrate_ext_flag in ('T', 'F'))
) organization index;
create unique index at_rating_spec_u1 on at_rating_spec (template_code, location_code, upper(version));

comment on table  at_rating_spec                              is 'Specifies a time series of ratings by location, parameters, and version';
comment on column at_rating_spec.rating_spec_code             is 'Synthetic key';
comment on column at_rating_spec.template_code                is 'References rating template';
comment on column at_rating_spec.location_code                is 'References location';
comment on column at_rating_spec.version                      is 'Version name of the rating time series';
comment on column at_rating_spec.source_agency_code           is 'Reference to a location group for the source agency';
comment on column at_rating_spec.in_range_rating_method       is 'In-range date rating method using effective dates';
comment on column at_rating_spec.out_range_low_rating_method  is 'Low out-of-range date rating method using effective dates';
comment on column at_rating_spec.out_range_high_rating_method is 'High out-of-range date rating method using effective dates';
comment on column at_rating_spec.active_flag                  is 'Specifies whether the rating time series is active';
comment on column at_rating_spec.auto_update_flag             is 'Specifies whether updates by the source agency should be stored automatically';
comment on column at_rating_spec.auto_activate_flag           is 'Specifies whether updates by the source agency should be activated automatically';
comment on column at_rating_spec.auto_migrate_ext_flag        is 'Specifies whether automatically stored updates should have existing extensions applied automatically';
comment on column at_rating_spec.description                  is 'USGS-style rounding specification for dependent parameter';
comment on column at_rating_spec.description                  is 'Description of rating time series';

----------------------------
-- AT_RATING_IND_ROUNDING --
----------------------------
create table at_rating_ind_rounding
(
   rating_spec_code   number(10),
   parameter_position number(1),
   rounding_spec      varchar2(10),
   constraint at_rating_ind_rounding_pk  primary key (rating_spec_code, parameter_position),
   constraint at_rating_ind_rounding_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code)
) organization index;

comment on table  at_rating_ind_rounding                    is 'Rounding specifications for rating input parameters';
comment on column at_rating_ind_rounding.rating_spec_code   is 'References rating specification';
comment on column at_rating_ind_rounding.parameter_position is 'Input parameter ordinal position';
comment on column at_rating_ind_rounding.rounding_spec      is 'USGS-style rounding specification';

---------------
-- AT_RATING --
---------------
create table at_rating
(
   rating_code      number(10),
   rating_spec_code number(10),
   effective_date   date        not null,
   ref_rating_code  number(10),
   create_date      date        not null,
   active_flag      varchar2(1) not null,
   formula          varchar2(1000),
   native_units     varchar2(256),
   description      varchar2(256),
   constraint at_rating_pk  primary key (rating_code),
   constraint at_rating_u1  unique (rating_spec_code, effective_date) using index,
   constraint at_rating_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_rating_fk2 foreign key (ref_rating_code) references at_rating (rating_code),
   constraint at_rating_ck1 check (active_flag in ('T', 'F'))
) organization index;

comment on table  at_rating                  is 'A dated rating in a rating time series';
comment on column at_rating.rating_code      is 'Synthetic key';
comment on column at_rating.rating_spec_code is 'References rating specification';
comment on column at_rating.ref_rating_code  is 'References a parent rating (for shift, offsets, etc...)';
comment on column at_rating.effective_date   is 'The earliest time the rating is in effect';
comment on column at_rating.create_date      is 'The time the rating is loaded into the database';
comment on column at_rating.active_flag      is 'Specifies whether the rating is active';
comment on column at_rating.formula          is 'Formula to be used instead of rating values';
comment on column at_rating.native_units     is 'Units used for i/o and for formula, in format ind1_unit[,ind2_unit[,...]];dep_unit';
comment on column at_rating.description      is 'Text description of rating specifics';

-----------------------------
-- AT_RATING_IND_PARAMETER --
-----------------------------
create table at_rating_ind_parameter
(
   rating_ind_param_code number(10),
   rating_code           number(10) not null,
   ind_param_spec_code   number(10) not null,
   constraint at_rating_ind_parameter_pk  primary key (rating_ind_param_code),
   constraint at_rating_ind_parameter_fk1 foreign key (rating_code) references at_rating (rating_code),
   constraint at_rating_ind_parameter_fk2 foreign key (ind_param_spec_code) references at_rating_ind_param_spec (ind_param_spec_code) 
);

comment on table  at_rating_ind_parameter                       is 'Associates a formula or rating values with a rating parameter';
comment on column at_rating_ind_parameter.rating_ind_param_code is 'Synthetic key';
comment on column at_rating_ind_parameter.rating_code           is 'Reference to parent rating';
comment on column at_rating_ind_parameter.ind_param_spec_code   is 'Reference to independent parameter specification';

--------------------------
-- AT_RATING_VALUE_NOTE --
--------------------------
create table at_rating_value_note
(
   note_code   number(10),
   office_code number(10),
   note_id     varchar2(16)  not null,
   description varchar2(256),
   constraint at_rating_value_note_pk  primary key (note_code),
   constraint at_rating_value_note_u1  unique (office_code, note_id) using index,
   constraint at_rating_value_note_ck1 check (note_id = upper(note_id)),
   constraint at_rating_value_note_fk1 foreign key (office_code) references cwms_office(office_code)
) organization index;

comment on table  at_rating_value_note             is 'Provides notation for specific rating values';
comment on column at_rating_value_note.note_code   is 'Synthetic key';
comment on column at_rating_value_note.office_code is 'Reference to office that created the note';
comment on column at_rating_value_note.note_id     is 'Note text';
comment on column at_rating_value_note.description is 'Note description';

insert into at_rating_value_note values (1, 53, 'BASE'        , 'Value is on base table');
insert into at_rating_value_note values (2, 53, 'INTERPOLATED', 'Value is interpolated between adjacent values');
insert into at_rating_value_note values (3, 53, 'MANUAL'      , 'Value was entered manually');

--------------------
-- AT_RATING_VALUE --
---------------------
create table at_rating_value
(
    rating_ind_param_code     number(10),
    other_ind_hash            varchar2(40),
    ind_value                 binary_double,
    dep_value                 binary_double,
    dep_rating_ind_param_code number(10),
    note_code                 number(10),
    constraint at_rating_value_pk  primary key (rating_ind_param_code, other_ind_hash, ind_value),
    constraint at_rating_value_ck1 check (dep_value is null or dep_rating_ind_param_code is null),
    constraint at_rating_value_ck2 check (dep_value is not null or dep_rating_ind_param_code is not null),
    constraint at_rating_value_fk1 foreign key (rating_ind_param_code) references at_rating_ind_parameter (rating_ind_param_code),
    constraint at_rating_value_fk2 foreign key (dep_rating_ind_param_code) references at_rating_ind_parameter (rating_ind_param_code),
    constraint at_rating_value_fk3 foreign key (note_code) references at_rating_value_note (note_code)
) organization index;

comment on table  at_rating_value                           is 'Specifies rating values';
comment on column at_rating_value.rating_ind_param_code     is 'References rating parameter';
comment on column at_rating_value.other_ind_hash            is 'Unique identifier of previous-position independent values';
comment on column at_rating_value.ind_value                 is 'Independent value for rating';
comment on column at_rating_value.dep_value                 is 'Dependent value for rating';
comment on column at_rating_value.dep_rating_ind_param_code is 'Dependent table for rating (for multi-parameter ratings)';
comment on column at_rating_value.note_code                 is 'Reference to rating value note';

create or replace trigger at_rating_value_trig
after insert or delete or update
on at_rating_value
declare
begin
   cwms_util.set_boolean_state('at_rating_value modified', true);
end;
/

-------------------------------
-- AT_RATING_EXTENSION_VALUE --
-------------------------------
create table at_rating_extension_value
(
    rating_ind_param_code     number(10),
    other_ind_hash            varchar2(40),
    ind_value                 binary_double,
    dep_value                 binary_double,
    dep_rating_ind_param_code number(10),
    note_code                 number(10),
    constraint at_rating_extension_value_pk  primary key (rating_ind_param_code, other_ind_hash, ind_value),
    constraint at_rating_extension_value_ck1 check (dep_value is null or dep_rating_ind_param_code is null),
    constraint at_rating_extension_value_ck2 check (dep_value is not null or dep_rating_ind_param_code is not null),
    constraint at_rating_extension_value_fk1 foreign key (rating_ind_param_code) references at_rating_ind_parameter (rating_ind_param_code),
    constraint at_rating_extension_value_fk2 foreign key (dep_rating_ind_param_code) references at_rating_ind_parameter (rating_ind_param_code),
    constraint at_rating_extension_value_fk3 foreign key (note_code) references at_rating_value_note (note_code)
) organization index;

comment on table  at_rating_extension_value                           is 'Specifies rating extension values';
comment on column at_rating_extension_value.rating_ind_param_code     is 'References rating parameter';
comment on column at_rating_extension_value.other_ind_hash            is 'Unique identifier of previous-position independent values';
comment on column at_rating_extension_value.ind_value                 is 'Independent value for rating';
comment on column at_rating_extension_value.dep_value                 is 'Dependent value for rating';
comment on column at_rating_extension_value.dep_rating_ind_param_code is 'Dependent table for rating (for multi-parameter ratings)';
comment on column at_rating_extension_value.note_code                 is 'Reference to rating value note';

------------------------
-- AT_COMPOUND_RATING --
------------------------
create global temporary table at_compound_rating(
   seq       integer,
   position  integer,
   ind_value binary_double,
   parent_id varchar2(4000),
   constraint at_compound_rating_pk primary key(seq)
) on commit delete rows;

create index at_compound_rating_idx on at_compound_rating(position, parent_id);

comment on table  at_compound_rating           is 'Temp table used for parsing ratings xml into objects';
comment on column at_compound_rating.seq       is 'Synthetic key';
comment on column at_compound_rating.position  is 'Independent parameter position';
comment on column at_compound_rating.ind_value is 'Independent parameter value';
comment on column at_compound_rating.parent_id is 'Id specifying upstream lower-position parameter position/value combinations';

   