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
)
organization index
tablespace CWMS_20AT_DATA;

create unique index at_rating_template_u1 on at_rating_template(office_code, upper(parameters_id), upper(version)) tablespace cwms_20at_data;

comment on table  at_rating_template                      is 'Templates for rating tables';
comment on column at_rating_template.template_code        is 'Synthetic key';
comment on column at_rating_template.office_code          is 'Reference to office';
comment on column at_rating_template.parameters_id        is 'Concatenation of parameters utilized and version in form ind1[,ind2[,..]];dep.version';
comment on column at_rating_template.version              is 'Version label, for different rating methods, etc...';
comment on column at_rating_template.dep_parameter_code   is 'Reference to parameter';
comment on column at_rating_template.description          is 'Text description of template';

commit;

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
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_rating_ind_param_spec                              is 'Independent parameters for rating templates';
comment on column at_rating_ind_param_spec.template_code                is 'Reference to rating template';
comment on column at_rating_ind_param_spec.parameter_code               is 'Reference to parameter';
comment on column at_rating_ind_param_spec.parameter_position           is 'Ordinal position of independent parameter in rating';
comment on column at_rating_ind_param_spec.in_range_rating_method       is 'Reference to in-range rating method for the indpendent parameter';
comment on column at_rating_ind_param_spec.out_range_low_rating_method  is 'Reference to low out-of-range rating method for the indpendent parameter';
comment on column at_rating_ind_param_spec.out_range_high_rating_method is 'Reference to high out-of-range rating method for the indpendent parameter';

commit;

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
   constraint at_rating_spec_fk3 foreign key (source_agency_code) references at_entity (entity_code), 
   constraint at_rating_spec_fk4 foreign key (in_range_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_fk5 foreign key (out_range_low_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_fk6 foreign key (out_range_high_rating_method) references cwms_rating_method (rating_method_code),
   constraint at_rating_spec_ck1 check (active_flag in ('T', 'F')),
   constraint at_rating_spec_ck2 check (auto_update_flag in ('T', 'F')),
   constraint at_rating_spec_ck3 check (auto_activate_flag in ('T', 'F')),
   constraint at_rating_spec_ck4 check (auto_migrate_ext_flag in ('T', 'F'))
)
organization index
tablespace CWMS_20AT_DATA;

create unique index at_rating_spec_u1 on at_rating_spec (template_code, location_code, upper(version)) tablespace cwms_20at_data;

comment on table  at_rating_spec                              is 'Specifies a time series of ratings by location, parameters, and version';
comment on column at_rating_spec.rating_spec_code             is 'Synthetic key';
comment on column at_rating_spec.template_code                is 'References rating template';
comment on column at_rating_spec.location_code                is 'References location';
comment on column at_rating_spec.version                      is 'Version name of the rating time series';
comment on column at_rating_spec.source_agency_code           is 'Reference to an entity for the source agency';
comment on column at_rating_spec.in_range_rating_method       is 'In-range date rating method using effective dates';
comment on column at_rating_spec.out_range_low_rating_method  is 'Low out-of-range date rating method using effective dates';
comment on column at_rating_spec.out_range_high_rating_method is 'High out-of-range date rating method using effective dates';
comment on column at_rating_spec.active_flag                  is 'Specifies whether the rating time series is active';
comment on column at_rating_spec.auto_update_flag             is 'Specifies whether updates by the source agency should be stored automatically';
comment on column at_rating_spec.auto_activate_flag           is 'Specifies whether updates by the source agency should be activated automatically';
comment on column at_rating_spec.auto_migrate_ext_flag        is 'Specifies whether automatically stored updates should have existing extensions applied automatically';
comment on column at_rating_spec.description                  is 'Description of rating time series';

commit;

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
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_rating_ind_rounding                    is 'Rounding specifications for rating input parameters';
comment on column at_rating_ind_rounding.rating_spec_code   is 'References rating specification';
comment on column at_rating_ind_rounding.parameter_position is 'Input parameter ordinal position';
comment on column at_rating_ind_rounding.rounding_spec      is 'USGS-style rounding specification';

commit;

---------------
-- AT_RATING --
---------------
create table at_rating
(
   rating_code      number(10),
   rating_spec_code number(10),
   effective_date   date        not null,
   ref_rating_code  number(10),
   transition_date  date,
   create_date      date        not null,
   active_flag      varchar2(1) not null,
   formula          varchar2(1000),
   native_units     varchar2(256),
   description      varchar2(256),
   constraint at_rating_pk  primary key (rating_code),
   constraint at_rating_u1  unique (rating_spec_code, effective_date) using index,
   constraint at_rating_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_rating_fk2 foreign key (ref_rating_code) references at_rating (rating_code),
   constraint at_rating_ck1 check (active_flag in ('T', 'F')),
   constraint at_rating_ck2 check (transition_date is null or transition_date < effective_date)
)
organization index
tablespace CWMS_20DATA;

comment on table  at_rating                  is 'A dated rating in a rating time series';
comment on column at_rating.rating_code      is 'Synthetic key';
comment on column at_rating.rating_spec_code is 'References rating specification';
comment on column at_rating.ref_rating_code  is 'References a parent rating (for shift, offsets, etc...)';
comment on column at_rating.effective_date   is 'The earliest time the rating is in effect';
comment on column at_rating.transition_date  is 'The time to start transition (interpolation) from previous rating';
comment on column at_rating.create_date      is 'The time the rating is loaded into the database';
comment on column at_rating.active_flag      is 'Specifies whether the rating is active';
comment on column at_rating.formula          is 'Formula to be used instead of rating values';
comment on column at_rating.native_units     is 'Units used for i/o and for formula, in format ind1_unit[,ind2_unit[,...]];dep_unit';
comment on column at_rating.description      is 'Text description of rating specifics';

commit;

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
)
tablespace CWMS_20AT_DATA;

comment on table  at_rating_ind_parameter                       is 'Associates a formula or rating values with a rating parameter';
comment on column at_rating_ind_parameter.rating_ind_param_code is 'Synthetic key';
comment on column at_rating_ind_parameter.rating_code           is 'Reference to parent rating';
comment on column at_rating_ind_parameter.ind_param_spec_code   is 'Reference to independent parameter specification';

commit;

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
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_rating_value_note             is 'Provides notation for specific rating values';
comment on column at_rating_value_note.note_code   is 'Synthetic key';
comment on column at_rating_value_note.office_code is 'Reference to office that created the note';
comment on column at_rating_value_note.note_id     is 'Note text';
comment on column at_rating_value_note.description is 'Note description';

insert into at_rating_value_note values (1, 53, 'BASE'        , 'Value is on base table');
insert into at_rating_value_note values (2, 53, 'INTERPOLATED', 'Value is interpolated between adjacent values');
insert into at_rating_value_note values (3, 53, 'MANUAL'      , 'Value was entered manually');

commit;

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
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_rating_value                           is 'Specifies rating values';
comment on column at_rating_value.rating_ind_param_code     is 'References rating parameter';
comment on column at_rating_value.other_ind_hash            is 'Unique identifier of previous-position independent values';
comment on column at_rating_value.ind_value                 is 'Independent value for rating';
comment on column at_rating_value.dep_value                 is 'Dependent value for rating';
comment on column at_rating_value.dep_rating_ind_param_code is 'Dependent table for rating (for multi-parameter ratings)';
comment on column at_rating_value.note_code                 is 'Reference to rating value note';

create index at_rating_value_dep_idx on at_rating_value(dep_rating_ind_param_code) tablespace cwms_20data;
commit;

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
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_rating_extension_value                           is 'Specifies rating extension values';
comment on column at_rating_extension_value.rating_ind_param_code     is 'References rating parameter';
comment on column at_rating_extension_value.other_ind_hash            is 'Unique identifier of previous-position independent values';
comment on column at_rating_extension_value.ind_value                 is 'Independent value for rating';
comment on column at_rating_extension_value.dep_value                 is 'Dependent value for rating';
comment on column at_rating_extension_value.dep_rating_ind_param_code is 'Dependent table for rating (for multi-parameter ratings)';
comment on column at_rating_extension_value.note_code                 is 'Reference to rating value note';

commit;

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

commit;

-----------------------
-- AT_VIRTUAL_RATING --
-----------------------
create table at_virtual_rating (
   virtual_rating_code number(10)   not null,
   rating_spec_code    number(10)   not null,
   effective_date      date         not null,
   transition_date     date,
   create_date         date         not null,
   active_flag         varchar2(1)  not null,
   connections         varchar2(80) not null,
   description         varchar2(256),
   constraint at_virtual_rating_pk  primary key (virtual_rating_code),
   constraint at_virtual_rating_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_virtual_rating_ck1 check (active_flag in ('T', 'F')),
   constraint at_virtual_rating_ck2 check (regexp_instr(connections, 'R\d(D|I\d)=(I\d|R\d(D|I\d))(,R\d(D|I\d)=(I\d|R\d(D|I\d)))*', 1, 1, 0, 'i') = 1),
   constraint at_virtual_rating_ck3 check (transition_date is null or transition_date < effective_date)
)
organization index
tablespace CWMS_20DATA;

comment on table  at_virtual_rating is 'Holds information about virtual ratings';
comment on column at_virtual_rating.virtual_rating_code is 'Synthetic key';
comment on column at_virtual_rating.rating_spec_code    is 'Foreign key to rating specification for this virtual rating';
comment on column at_virtual_rating.effective_date      is 'Earliest date/time this rating was in effect';
comment on column at_virtual_rating.transition_date     is 'The time to start transition (interpolation) from previous rating';
comment on column at_virtual_rating.create_date         is 'Date/time this rating was stored to database';
comment on column at_virtual_rating.active_flag         is 'Flag (T/F) specifying whether this rating is active';
comment on column at_virtual_rating.connections         is 'String specifying how source ratings are connected to form virtual rating';
comment on column at_virtual_rating.description         is 'Descriptive text about this virtual rating';

commit;

-------------------------------
-- AT_VIRTUAL_RATING_ELEMENT --
-------------------------------
create table at_virtual_rating_element (
   virtual_rating_element_code number(10),
   virtual_rating_code         number(10),
   position                    integer,
   rating_spec_code            number(10),
   rating_expression           varchar2(32),
   constraint at_virtual_rating_element_pk  primary key (virtual_rating_element_code),
   constraint at_virtual_rating_element_fk1 foreign key (virtual_rating_code) references at_virtual_rating (virtual_rating_code),
   constraint at_virtual_rating_element_fk2 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_virtual_rating_element_ck1 check ((rating_spec_code is null or  rating_expression is null) and not 
                                                   (rating_spec_code is null and rating_expression is null))
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_virtual_rating_element is 'Holds source ratings (rating specs or rating expressions) for virtual ratings';
comment on column at_virtual_rating_element.virtual_rating_element_code is 'Synthetic key';
comment on column at_virtual_rating_element.virtual_rating_code         is 'Foreign key to the virtual rating that this source rating is for';
comment on column at_virtual_rating_element.position                    is 'The sequential position of this source rating in the virtual rating';
comment on column at_virtual_rating_element.rating_spec_code            is 'Foreign key to the rating spec for this source rating if it is a rating';
comment on column at_virtual_rating_element.rating_expression           is 'Mathematical expression for this source rating if it is an expression. For longer expressions use formula-based ratings.';

commit;

----------------------------
-- AT_VIRTUAL_RATING_UNIT --
----------------------------
create table at_virtual_rating_unit (
   virtual_rating_element_code number(10),
   position                    integer,
   unit_code                   number(10) not null,
   constraint at_virtual_rating_unit_pk  primary key (virtual_rating_element_code, position),
   constraint at_virtual_rating_unit_fk1 foreign key (virtual_rating_element_code) references at_virtual_rating_element (virtual_rating_element_code),
   constraint at_virtual_rating_unit_fk2 foreign key (unit_code) references cwms_unit (unit_code)
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_virtual_rating_unit is 'Holds units for virtual rating elements (source ratings)';
comment on column at_virtual_rating_unit.virtual_rating_element_code is 'Foreign key to the virtual rating element this unit is for';
comment on column at_virtual_rating_unit.position                    is 'Sequential position of the paramter in the virtual rating element that this unit is for';
comment on column at_virtual_rating_unit.unit_code                   is 'Foreign key intto the units table for this unit';

commit;

----------------------------
-- AT_TRANSITIONAL_RATING --
----------------------------
create table at_transitional_rating(
   transitional_rating_code number(10)    not null,
   rating_spec_code         number(10)    not null,
   effective_date           date          not null,
   transition_date          date,
   create_date              date          not null,
   active_flag              varchar2(1)   not null,
   native_units             varchar2(256) not null,
   description              varchar2(256),
   constraint at_transitional_rating_pk  primary key (transitional_rating_code),
   constraint at_transitional_rating_fk1 foreign key(rating_spec_code) references at_rating_spec(rating_spec_code), 
   constraint at_transitional_rating_ck1 check (active_flag in ('T', 'F')),
   constraint at_transitional_rating_ck2 check (transition_date is null or transition_date < effective_date)
) organization index
  tablespace cwms_20data;

comment on table  at_transitional_rating is 'Holds information about transitional ratings';
comment on column at_transitional_rating.transitional_rating_code is 'Synthetic key';
comment on column at_transitional_rating.rating_spec_code         is 'Foreign key to rating specification for this transitional rating';
comment on column at_transitional_rating.effective_date           is 'Earliest date/time this rating was in effect';
comment on column at_transitional_rating.transition_date          is 'The time to start transition (interpolation) from previous rating';
comment on column at_transitional_rating.create_date              is 'Date/time this rating was stored to database';
comment on column at_transitional_rating.active_flag              is 'Flag (T/F) specifying whether this rating is active';
comment on column at_transitional_rating.native_units             is 'Units used for selection and evaluation, in format ind1_unit[,ind2_unit[,...]];dep_unit';
comment on column at_transitional_rating.description              is 'Descriptive text about this transitional rating';

commit;

--------------------------------
-- AT_TRANSITIONAL_RATING_SRC --
--------------------------------
create table at_transitional_rating_src
(
  transitional_rating_code     number(10) not null,
  position                     integer    not null,
  rating_spec_code             number(10) not null,
  constraint at_trans_rating_src_pk  primary key (transitional_rating_code, position),
  constraint at_trans_rating_src_ck1 check (position > 0), 
  constraint at_trans_rating_src_fk1 foreign key(transitional_rating_code) references at_transitional_rating(transitional_rating_code), 
  constraint at_trans_rating_src_fk2 foreign key(rating_spec_code) references at_rating_spec(rating_spec_code) 
) organization index
  tablespace cwms_20at_data;

comment on table  at_transitional_rating_src is 'Holds source ratings for transitional ratings';
comment on column at_transitional_rating_src.transitional_rating_code is     'Foreign key to the transitional rating that this alternative rating is for';
comment on column at_transitional_rating_src.position is                     'The sequential position of this source rating in the transitional rating';
comment on column at_transitional_rating_src.rating_spec_code is             'Foreign key to the rating spec for this alternative rating';

commit;

--------------------------------
-- AT_TRANSITIONAL_RATING_SEL --
--------------------------------
create table at_transitional_rating_sel
(
  transitional_rating_code     number(10) not null,
  position                     integer    not null,
  expression                   varchar2(256) not null,
  condition                    varchar2(1024),
  constraint at_trans_rating_sel_pk  primary key (transitional_rating_code, position),
  constraint at_trans_rating_sel_ck1 check (position > -1), 
  constraint at_trans_rating_sel_ck2 check (position > 0 or condition is null), 
  constraint at_trans_rating_sel_ck3 check (not (position > 0 and condition is null)), 
  constraint at_trans_rating_sel_fk1 foreign key(transitional_rating_code) references at_transitional_rating(transitional_rating_code)
) organization index
  tablespace cwms_20at_data;
  
comment on table  at_transitional_rating_sel is 'Holds selection information for transitional ratings';  
comment on column at_transitional_rating_sel.transitional_rating_code is 'Foreign key to the transitional rating this selection is for';  
comment on column at_transitional_rating_sel.position is 'The sequential order of this selection.  Selections are evaluated in sequential order.';  
comment on column at_transitional_rating_sel.expression is 'The expression which yields the result of the rating if this condition is null or evaulates to true.';  
comment on column at_transitional_rating_sel.condition is 'The condition to be evaluated to determine if the expression is used as the result of the rating';  

commit;

-------------------------
-- AT_USGS_RATING_HASH --
-------------------------
create table at_usgs_rating_hash (
   rating_spec_code integer,
   hash_value       varchar2(40),
   constraint at_usgs_rating_hash_pk  primary key (rating_spec_code) using index,
   constraint at_usgs_rating_hash_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code)
) tablespace cwms_20at_data;

comment on table  at_usgs_rating_hash is 'Holds hash codes for rating text from USGS NWIS';
comment on column at_usgs_rating_hash.rating_spec_code is 'The rating specification for this hash code';
comment on column at_usgs_rating_hash.hash_value       is 'The hash value for this rating specification';   

commit;

-----------------
-- AT_OVERFLOW --
-----------------
create table at_overflow (
   overflow_location_code number(10),
   crest_elevation        binary_double,
   length_or_diameter     binary_double,
   is_circular            varchar2(1),
   rating_spec_code       number(10),
   description            varchar2(128),
   constraint at_overflow_pk  primary key (overflow_location_code),
   constraint at_overflow_fk1 foreign key (overflow_location_code) references at_outlet (outlet_location_code),
   constraint at_overflow_fk2 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_overflow_ck1 check (length_or_diameter is NULL or is_circular in ('T', 'F'))
) tablespace cwms_20data;

comment on table  at_overflow is 'Holds information on uncontrolled overflow spillway or weir';
comment on column at_overflow.overflow_location_code is 'The location code for this overflow';
comment on column at_overflow.crest_elevation        is 'The crest elevation in meters for this overflow';
comment on column at_overflow.length_or_diameter     is 'The crest length (or diameter for circular spillways) in meters';
comment on column at_overflow.is_circular            is 'A flag (''T''/''F'') specifying wheter the overflow is circular';
comment on column at_overflow.rating_spec_code       is 'A reference to the elevation-discharge rating specification';
comment on column at_overflow.description            is 'A description of the overflow';

commit;


 
