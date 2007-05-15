

/*** CWMS_RATING_TYPE ***/


alter table at_rating drop constraint at_rating_fk1;

drop table cwms_rating_type;

create table cwms_rating_type
( rating_type_code  number(10),
  rating_type_id    varchar2(16) not null,
  long_name         varchar2(32));

alter table cwms_rating_type add constraint cwms_rating_type_pk 
primary key (rating_type_code);

create unique index cwms_rating_type_ak1 on cwms_rating_type (rating_type_id);

comment on table  cwms_rating_type                is 'Table of rating family names';
comment on column cwms_rating_type.rating_type_id is 'Short name for the rating type ("STGQ", "ELST")';
comment on column cwms_rating_type.long_name      is 'Long name for the rating type ("Stage-Flow", "Elevation-Storage")';

insert into cwms_rating_type values (1,'STGQ','Stage-Flow');
insert into cwms_rating_type values (2,'ELST','Elevation-Storage');
insert into cwms_rating_type values (3,'ELSA','Elevation-Surface Area');


/*** CWMS_RATING_INTERPOLATE ***/


alter table at_rating drop constraint at_rating_fk2;

drop table cwms_rating_interpolate;

create table cwms_rating_interpolate
( interpolate_code  number(10),
  interpolate_id    varchar2(16) not null);

alter table cwms_rating_interpolate add constraint cwms_rating_interp_pk 
primary key (interpolate_code);

create unique index cwms_rating_interp_ak1 on cwms_rating_interpolate (interpolate_id);

comment on table  cwms_rating_interpolate                is 'Table of rating curve expansion functions';
comment on column cwms_rating_interpolate.interpolate_id is 'USGS "RATING EXPANSION" ("LOGARITHMIC")';

insert into cwms_rating_interpolate values (1,'LINEAR');
insert into cwms_rating_interpolate values (2,'LOGARITHMIC');


/*** AT_RATING ***/


alter table at_rating_parameters drop constraint at_rating_parms_fk1;
alter table at_rating_loc        drop constraint at_rating_loc_fk1;

drop table at_rating; 

create table at_rating
( rating_code       number(10),
  db_office_code    number(6)    not null,
  source            varchar2(32) not null,
  rating_type_code  number(10)   not null,
  interpolate_code  number(10)   not null,
  indep_parm_count  number(4)    not null,
  description       varchar2(160));

alter table at_rating add constraint at_rating_pk 
primary key (rating_code);

alter table at_rating add constraint at_rating_fk1 
foreign key (rating_type_code) references cwms_rating_type;

alter table at_rating add constraint at_rating_fk2 
foreign key (interpolate_code) references cwms_rating_interpolate;
 
create unique index at_rating_ak1 on at_rating
( db_office_code, 
  source, 
  rating_type_code);

comment on table  at_rating                  is 'Defines a specific set of parameters for a rating family';
comment on column at_rating.rating_code      is 'Synthetic key';
comment on column at_rating.source           is 'Rating table source, office or agency name';
comment on column at_rating.rating_type_code is 'Foreign key to the rating type ("STGQ", "ELST")';
comment on column at_rating.interpolate_code is 'Foreign key to the interpolation type ("LOGARITHMIC")';
comment on column at_rating.indep_parm_count is 'Number of independent variables (1 or 2)';


/*** AT_RATING_PARMETERS ***/


alter table at_rating_version drop constraint at_rating_version_fk1;

drop table at_rating_parameters;


create table at_rating_parameters
( rating_parms_code number(10),
  rating_code       number(10) not null,
  indep_parm_code_1 number(10) not null,
  indep_parm_code_2 number(10),
  dep_parm_code     number(10) not null,
  description       varchar2(160));

alter table at_rating_parameters add constraint at_rating_parms_pk 
primary key (rating_parms_code);

alter table at_rating_parameters add constraint at_rating_parms_fk1 
foreign key (rating_code) references at_rating;
 
create unique index at_rating_parms_ak1 on at_rating_parameters
( rating_code, 
  indep_parm_code_1, 
  indep_parm_code_2,
  dep_parm_code);

comment on table at_rating_parameters is 'Defines a set of parameters for a rating family';


/*** AT_RATING_VERSION ***/


drop table at_rating_version;

create table at_rating_version
( rating_parms_code  number(10),
  version            varchar2(32),
  constraint         at_rating_version_pk primary key (rating_parms_code, version))
organization index;

alter table at_rating_version add constraint at_rating_version_fk1 
foreign key (rating_parms_code) references at_rating_parameters;

comment on table  at_rating_version         is 'Defines a Version set for a specific parameter set for a rating family';
comment on column at_rating_version.version is 'Versions to rate for this parameter set';


/***  AT_RATING_LOC  ***/


alter table at_rating_extension drop constraint at_rating_extension_fk1;
alter table at_rating_spec      drop constraint at_rating_spec_fk1;

drop table at_rating_loc;

create table at_rating_loc
( rating_loc_code   number(10), 
  rating_code       number(10)  not null,
  location_code     number(10)  not null,
  auto_load_flag    char(1)     not null,
  auto_active_flag  char(1)     not null,
  filename          varchar2(32),
  description       varchar2(160));

alter table at_rating_loc add constraint at_rating_loc_pk 
primary key (rating_loc_code);

alter table at_rating_loc add constraint at_rating_loc_fk1
foreign key (rating_code) references at_rating;

--
-- The following fk is for CWMS v1.x
-- It needs to be changed for CWMS v2
--

alter table at_rating_loc add constraint at_rating_loc_fk2
foreign key (location_code) references at_point_location;

alter table at_rating_loc add constraint at_rating_loc_ck1
check (auto_load_flag in ('T','F'));

alter table at_rating_loc add constraint at_rating_loc_ck2
check (auto_active_flag in ('T','F'));

create unique index at_rating_loc_ak1 on at_rating_loc
( rating_code, 
  location_code);

comment on table  at_rating_loc                  is 'Defines the metadata for a rating family at a location';
comment on column at_rating_loc.rating_code      is 'Foreign key to rating family';
comment on column at_rating_loc.location_code    is 'Foreign key to the cwms location to which this rating applies';
comment on column at_rating_loc.auto_load_flag   is '="T" to automatically load new curves and shifts when they become available';
comment on column at_rating_loc.auto_active_flag is '="T" to automatically mark newly loaded curves and shifts as active';
comment on column at_rating_loc.filename         is 'rating table filename (do we also need file type, "RDB" ?)';


/***  AT_RATING_EXTENSION  ***/


drop table at_rating_extension;

create table at_rating_extension
( rating_loc_code   number(10), 
  x                 number      not null,
  y                 number      not null);

alter table at_rating_extension add constraint at_rating_extension_pk 
primary key (rating_loc_code,x);

alter table at_rating_extension add constraint at_rating_extension_fk1
foreign key (rating_loc_code) references at_rating_loc;

comment on table at_rating_extension is 'Extends the top or bottom of the rating curves for a rating family at a location';


/***  AT_RATING_SPEC ***/


alter table at_rating_shift_spec drop constraint at_rating_shift_spec_fk1;
alter table at_rating_curve      drop constraint at_rating_curve_fk1;

drop table at_rating_spec;

create table at_rating_spec
( rating_spec_code  number(10),
  rating_loc_code   number(10)  not null,
  effective_date    date        not null,
  create_date       date        not null, 
  version           varchar2(8) not null,
  active_flag       char(1)     not null);

alter table at_rating_spec add constraint at_rating_spec_pk 
primary key (rating_spec_code);

alter table at_rating_spec add constraint at_rating_spec_fk1 
foreign key (rating_loc_code) references at_rating_loc;

alter table at_rating_spec add constraint at_rating_spec_ck1
check (active_flag in ('T','F'));
 
create unique index at_rating_spec_ak1 on at_rating_spec
( rating_loc_code, 
  effective_date);  

comment on table  at_rating_spec                  is 'Defines a specific rating table';
comment on column at_rating_spec.rating_spec_code is 'Synthetic key';
comment on column at_rating_spec.rating_loc_code  is 'Foreign key to rating family at a location';
comment on column at_rating_spec.effective_date   is 'The date on/after which this rating SHOULD be used';
comment on column at_rating_spec.create_date      is 'The date the rating table was stored in the database';
comment on column at_rating_spec.active_flag      is '="T" if the rating is to be used, else "F"';
comment on column at_rating_spec.version          is 'The base rating table version; the RATING ID in the USGS rdb file " 9.0"';


/*** AT_RATING_SHIFT_SPEC ***/


alter table at_rating_shift_values drop constraint at_rating_shift_values_fk1;

drop table at_rating_shift_spec;

create table at_rating_shift_spec
( rating_shift_code  number(10),
  rating_spec_code   number(10) not null,
  effective_date     date       not null,
  active_flag        char(1)    not null,
  transition_flag    char(1)    not null);

alter table at_rating_shift_spec add constraint at_rating_shift_spec_pk
primary key (rating_shift_code);
  
alter table at_rating_shift_spec add constraint at_rating_shift_spec_fk1
foreign key (rating_spec_code) references at_rating_spec;

alter table at_rating_shift_spec add constraint at_rating_shift_spec_ck1
check (active_flag in ('T','F'));

alter table at_rating_shift_spec add constraint at_rating_shift_spec_ck2
check (transition_flag in ('T','F'));

create unique index at_rating_shift_spec_ak1 on at_rating_shift_spec
( rating_spec_code,
  effective_date);

comment on table  at_rating_shift_spec                   is 'Associates shifts with a specific rating table';
comment on column at_rating_shift_spec.rating_shift_code is 'Synthetic key';
comment on column at_rating_shift_spec.rating_spec_code  is 'The base rating table this shift set applies to';
comment on column at_rating_shift_spec.effective_date    is 'The date on/after which this shift should be used';
comment on column at_rating_shift_spec.active_flag       is '="T" if the shift is to be used, else "F"';
comment on column at_rating_shift_spec.transition_flag   is '="T" if the shift is used to transition between official USGS ratings, else "F"';


/*** AT_RATING_SHIFT_VALUES ***/


drop table at_rating_shift_values;

create table at_rating_shift_values
( rating_shift_code  number(10),
  stage              number,
  shift              number     not null,
  constraint         at_rating_shift_values_pk 
  primary key       (rating_shift_code, stage))
organization index;

alter table at_rating_shift_values add constraint at_rating_shift_values_fk1
foreign key (rating_shift_code) references at_rating_shift_spec;

comment on table  at_rating_shift_values       is 'Table of one or more shifts to be applied to a specific rating table';
comment on column at_rating_shift_values.stage is 'The value of INDEP_PARM_1 where this shift begins';
comment on column at_rating_shift_values.shift is 'The value to add to INDEP_PARM_1 before rating the value';


/*** AT_RATING_CURVE ***/


alter table at_rating_value drop constraint at_rating_value_fk1;

drop table at_rating_curve;

create table at_rating_curve
( rating_curve_code  number(10),
  rating_spec_code   number(10) not null,
  indep_parm_number  number(4)  not null,
  indep_parm_value   number);

alter table at_rating_curve add constraint at_rating_curve_pk
primary key (rating_curve_code);

alter table at_rating_curve add constraint at_rating_curve_fk1
foreign key (rating_spec_code) references at_rating_spec;

create unique index at_rating_curve_ak1 on at_rating_curve 
( rating_spec_code,
  indep_parm_number,
  indep_parm_value);

comment on table  at_rating_curve                   is 'Associates rating curves with a specific rating table';
comment on column at_rating_curve.rating_curve_code is 'Synthetic key';
comment on column at_rating_curve.rating_spec_code  is 'Points to a specific rating table';
comment on column at_rating_curve.indep_parm_number is '=1..n, where n=the number of independent parmameters';
comment on column at_rating_curve.indep_parm_value  is 'The value of the second independent parameter for this curve, NULL if INDEP_PARM_NUMBER=1';


/*** AT_RATING_VALUE ***/


drop table at_rating_value;

create table at_rating_value
( rating_curve_code  number(10),
  x                  number,
  y                  number       not null,
  stor_flag          char(1), 
  constraint         at_rating_value_pk
  primary key       (rating_curve_code,x))
organization index;

alter table at_rating_value add constraint at_rating_value_fk1
foreign key (rating_curve_code) references at_rating_curve;

alter table at_rating_value add constraint at_rating_value_ck1
check (stor_flag in ('T','F'));

comment on table  at_rating_value           is 'Table of expanded (base) rating table values';
comment on column at_rating_value.stor_flag is '="T" if it is a USGS STOR point marked by an asterisk, else "F"';
/
