/* CWMS_RATING_INTERPOLATE */

 
alter table at_rating drop constraint at_rating_fk1;

drop table cwms_rating_interpolate;

create table cwms_rating_interpolate
( interpolate_code  number(4),
  interpolate_id    varchar2(16) not null,
  constraint        at_rating_interpolate_pk
  primary key      (interpolate_code))
organization index;

insert into cwms_rating_interpolate values (1,'LINEAR');
insert into cwms_rating_interpolate values (2,'LOGARITHMIC');


/* AT_RATING */


alter table at_rating_parameters drop constraint at_rating_parms_fk1;
alter table at_rating_spec       drop constraint at_rating_spec_fk1;

drop table at_rating; 

create table at_rating
( rating_code       number(6),
  db_office_code    number(6)    not null,
  agency_code       number(6)    not null,
  rating_id         varchar2(16) not null,
  interpolate_code  number(4)    not null,
  indep_parm_count  number(4)    not null,
  indep_unit_code_1 number(4),
  indep_unit_code_2 number(4),
  dep_unit_code     number(4),
  description       varchar2(160));

alter table at_rating add constraint at_rating_pk primary key (rating_code);

alter table at_rating add constraint at_rating_fk1 
foreign key (interpolate_code) references cwms_rating_interpolate;

--
-- change the referenced table below to cwms_office
--

alter table at_rating add constraint at_rating_fk2 
foreign key (db_office_code) references at_office(office_code);
 
create unique index at_rating_ak1 on at_rating
( db_office_code, 
  agency_code, 
  rating_id);


comment on table at_rating is 'Defines a specific set of parameters for a general rating family';

comment on column at_rating.rating_code is 'Synthetic key';

comment on column at_rating.agency_code is 'The publishing agency';

comment on column at_rating.rating_id is 'Short name for the rating family ("STGQ", "ELST")';

comment on column at_rating.interpolate_code is 'Interpolation type ("LINEAR" or "LOGARITHMIC")';

comment on column at_rating.indep_parm_count is 'Number of independent variables (1 or 2)';

comment on column at_rating.indep_unit_code_1 is 'Default units used to convert the values of the 1st independent variable in the rating table to internal db units';

comment on column at_rating.indep_unit_code_2 is 'Default units used to convert the values of the 2nd independent variable in the rating table to internal db units';

comment on column at_rating.dep_unit_code is 'Default units used to convert the values of the dependent variable in the rating table to internal db units';


drop sequence seq_rating;

create sequence seq_rating nocache;

create or replace trigger at_rating_BIR
before insert on at_rating
for each row
declare
   l_nextval number;
begin
   select seq_rating.nextval into l_nextval from dual;
   :new.rating_code:=l_nextval;
end;
/


/* AT_RATING_PARMETERS */


alter table at_rating_version drop constraint at_rating_version_fk1;

drop table at_rating_parameters;


create table at_rating_parameters
( rating_parms_code number(4),
  rating_code       number(6)  not null,
  indep_parm_code_1 number(10) not null,
  indep_parm_code_2 number(10),
  dep_parm_code     number(10) not null,
  description       varchar2(160),
  constraint        at_rating_parms_pk 
  primary key      (rating_parms_code));

alter table at_rating_parameters add constraint at_rating_parms_fk1 
foreign key (rating_code) references at_rating;
 
create unique index at_rating_parms_ak1 on at_rating_parameters
( rating_code, 
  indep_parm_code_1, 
  indep_parm_code_2);


comment on table at_rating_parameters is 'Defines a specific set of parameters for a general rating family';


drop sequence seq_rating_parms;

create sequence seq_rating_parms nocache;

create or replace trigger at_rating_parameters_BIR
before insert on at_rating_parameters
for each row
declare
   l_nextval number;
begin
   select seq_rating_parms.nextval into l_nextval from dual;
   :new.rating_parms_code:=l_nextval;
end;
/


/* AT_RATING_VERSION */


drop table at_rating_version;

create table at_rating_version
( rating_parms_code  number(4),
  version            varchar2(32),
  constraint         at_rating_version_pk 
  primary key       (rating_parms_code, version))
organization index;

alter table at_rating_version add constraint at_rating_version_fk1 
foreign key (rating_parms_code) references at_rating_parameters;


comment on table at_rating_version is 'Defines a Version set for a specific parameter set for a general rating family';

comment on column at_rating_version.version is 'Versions to rate for this parameter set';


/*  AT_RATING_SPEC */


alter table at_rating_shift_spec drop constraint at_rating_shift_spec_fk1;
alter table at_rating_curve      drop constraint at_rating_curve_fk1;

drop table at_rating_spec;

create table at_rating_spec
( rating_spec_code  number(6),
  rating_code       number(6)  not null,
  location_code     number(10) not null,
  effective_date    date       not null,
  create_date       date       not null, 
  active_flag       varchar2(1),
  usgs_rating_id    number(4),
  filename          varchar2(32),
  description       varchar2(160),
  constraint        at_rating_spec_pk 
  primary key      (rating_spec_code));


alter table at_rating_spec add constraint at_rating_spec_ck1
check (active_flag is null or active_flag='Y');

alter table at_rating_spec add constraint at_rating_spec_fk1 
foreign key (rating_code) references at_rating;
 
create unique index at_rating_spec_ak1 on at_rating_spec
( rating_code, 
  location_code, 
  effective_date);  


comment on table at_rating_spec is 'Defines a specific rating table';

comment on column at_rating_spec.rating_spec_code is 'Synthetic key';

comment on column at_rating_spec.effective_date is 'The date on/after which this rating SHOULD be used';

comment on column at_rating_spec.create_date is 'The date the rating table was stored in the database';

comment on column at_rating_spec.active_flag is '="Y" if the rating is to be used, else null';

comment on column at_rating_spec.usgs_rating_id is 'the base rating table "version" number from the USGS rdb file';

comment on column at_rating_spec.filename is 'rating table filename (do we also need file type, "RDB" ?)';


drop sequence seq_rating_spec;

create sequence seq_rating_spec nocache;

create or replace trigger at_rating_spec_BIR
before insert on at_rating_spec
for each row
declare
   l_nextval number;
begin
   select seq_rating_spec.nextval into l_nextval from dual;
   :new.rating_spec_code:=l_nextval;
end;
/


/* AT_RATING_SHIFT_SPEC */


alter table at_rating_shift_values drop constraint at_rating_shift_values_fk1;

drop table at_rating_shift_spec;

create table at_rating_shift_spec
( rating_shift_code  number(6),
  rating_spec_code   number(6)    not null,
  effective_date     date         not null,
  active_flag        varchar2(1),
  transition_flag    varchar2(1), 
  constraint         at_rating_shift_spec_pk
  primary key       (rating_shift_code));


alter table at_rating_shift_spec add constraint at_rating_shift_spec_ck1
check (active_flag is null or active_flag='Y');

alter table at_rating_shift_spec add constraint at_rating_shift_spec_ck2
check (transition_flag is null or transition_flag='Y');
  
alter table at_rating_shift_spec add constraint at_rating_shift_spec_fk1
foreign key (rating_spec_code) references at_rating_spec;

create unique index at_rating_shift_spec_ak1 on at_rating_shift_spec
( rating_spec_code,
  effective_date);


comment on table at_rating_shift_spec is 'Associates shifts with a specific rating table';

comment on column at_rating_shift_spec.rating_shift_code is 'Synthetic key';

comment on column at_rating_shift_spec.rating_spec_code is 'The base rating table this shift set applies to';

comment on column at_rating_shift_spec.effective_date is 'The date on/after which this shift SHOULD be used';

comment on column at_rating_shift_spec.active_flag is '="Y" if the shift is to be used, else null';

comment on column at_rating_shift_spec.transition_flag is '="Y" if the shift is used to transition between official USGS ratings, else null';


drop sequence seq_rating_shift;

create sequence seq_rating_shift nocache;

create or replace trigger at_rating_shift_spec_BIR
before insert on at_rating_shift_spec
for each row
declare
   l_nextval number;
begin
   select seq_rating_shift.nextval into l_nextval from dual;
   :new.rating_shift_code:=l_nextval;
end;
/


/* AT_RATING_SHIFT_VALUES */


drop table at_rating_shift_values;

create table at_rating_shift_values
( rating_shift_code  number(6),
  stage              number,
  shift              number     not null,
  constraint         at_rating_shift_values_pk 
  primary key       (rating_shift_code, stage))
organization index;

alter table at_rating_shift_values add constraint at_rating_shift_values_fk1
foreign key (rating_shift_code) references at_rating_shift_spec;


comment on table at_rating_shift_values is 'Table of one or more shifts to be applied to a specific rating table';

comment on column at_rating_shift_values.stage is 'The value of INDEP_PARM_1 where this shift begins';

comment on column at_rating_shift_values.shift is 'The value to add to INDEP_PARM_1 before rating the value';


/* AT_RATING_CURVE */


alter table at_rating_value drop constraint at_rating_value_fk1;

drop table at_rating_curve;

create table at_rating_curve
( rating_curve_code  number(6),
  rating_spec_code   number(6)  not null,
  indep_parm_number  number(4)  not null,
  indep_parm_value   number,
  constraint         at_rating_curve_pk
  primary key       (rating_curve_code));

alter table at_rating_curve add constraint at_rating_curve_fk1
foreign key (rating_spec_code) references at_rating_spec;

create unique index at_rating_curve_ak1 on at_rating_curve 
( rating_spec_code,
  indep_parm_number,
  indep_parm_value);


comment on table at_rating_curve is 'Associates rating curves with a specific rating table';

comment on column at_rating_curve.rating_curve_code is 'Synthetic key';

comment on column at_rating_curve.rating_spec_code is 'Points to a specific rating table';

comment on column at_rating_curve.indep_parm_number is '=1..n, where n=the number of independent parmameters';

comment on column at_rating_curve.indep_parm_value is 'The value of the second independent parameter for this curve, NULL if INDEP_PARM_NUMBER=1';


drop sequence seq_rating_curve;

create sequence seq_rating_curve nocache;

create or replace trigger at_rating_curve_BIR
before insert on at_rating_curve
for each row
declare
   l_nextval number;
begin
   select seq_rating_curve.nextval into l_nextval from dual;
   :new.rating_curve_code:=l_nextval;
end;
/


/* AT_RATING_VALUE */


drop table at_rating_value;

create table at_rating_value
( rating_curve_code  number(6),
  x                  number,
  y                  number       not null,
  stor_flag          varchar2(1), 
  constraint         at_rating_value_pk
  primary key       (rating_curve_code,x))
organization index;

alter table at_rating_value add constraint at_rating_value_ck1
check (stor_flag is null or stor_flag='Y');

alter table at_rating_value add constraint at_rating_value_fk1
foreign key (rating_curve_code) references at_rating_curve;


comment on table at_rating_value is 'Table of expanded rating table values';

comment on column at_rating_value.stor_flag is 
'="Y" if it is a USGS STOR point marked by an asterisk, else null';


