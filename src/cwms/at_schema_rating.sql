/*** CWMS v2.0 ***/



declare
   type id_array_t is table of varchar2(32);
   table_names id_array_t := id_array_t(
      'at_rating_extension_value',
      'at_rating_extension_spec',
      'at_rating_value',
      'at_rating_curve',
      'at_rating_spec',
      'at_rating_loc',
      'at_rating',
      'at_rating_parameters',
      'cwms_rating_interpolate',
      'et_rdb_comment',
      'et_rdb_value');
   mview_names id_array_t := id_array_t(
      'mv_curve');

begin                
   for i in table_names.first .. table_names.last loop
      begin 
         execute immediate 'drop table ' || table_names(i) || ' cascade constraints';
         dbms_output.put_line('Dropped table ' || table_names(i));
      exception 
         when others then null;
      end;
   end loop;
      for i in mview_names.first .. mview_names.last loop
      begin 
         execute immediate 'drop materialized view  ' || mview_names(i);
         dbms_output.put_line('Dropped materialized view  ' || mview_names(i));
      exception 
         when others then null;
      end;
   end loop;
end;
/


/*---------------------*/
/* AT_RATING_PARMETERS */
/*---------------------*/


create table at_rating_parameters
( rating_parms_code number(10),
  indep_parm_code_1 number(10) not null,
  indep_parm_code_2 number(10),
  dep_parm_code     number(10) not null);

alter table at_rating_parameters add constraint at_rating_parms_pk 
primary key (rating_parms_code);

alter table at_rating_parameters add constraint at_rating_parms_fk1 
foreign key (indep_parm_code_1) references at_parameter(parameter_code);

alter table at_rating_parameters add constraint at_rating_parms_fk2 
foreign key (indep_parm_code_2) references at_parameter(parameter_code);

alter table at_rating_parameters add constraint at_rating_parms_fk3 
foreign key (dep_parm_code) references at_parameter(parameter_code);
 
create unique index at_rating_parms_ak1 on at_rating_parameters
( indep_parm_code_1, 
  indep_parm_code_2,
  dep_parm_code);

comment on table at_rating_parameters is 'Defines a set of table lookup parameters';


/*-----------*/
/* AT_RATING */
/*-----------*/


create table at_rating
( rating_code       number(10),
  db_office_code    number(6)    not null,
  source_agency     varchar2(32) not null,
  rating_parms_code number(10)   not null,
  indep_parm_count  number(4)    not null,
  indep_rounding_1  number(10),
  indep_rounding_2  number(10),
  dep_rounding      number(10),
  description       varchar2(200));

alter table at_rating add constraint at_rating_pk 
primary key (rating_code);

alter table at_rating add constraint at_rating_fk1 
foreign key (db_office_code) references cwms_office(office_code);

alter table at_rating add constraint at_rating_fk2
foreign key (rating_parms_code) references at_rating_parameters;
 
create unique index at_rating_ak1 on at_rating
( db_office_code, 
  source_agency, 
  rating_parms_code);

comment on table  at_rating                   is 'Defines a rating template for a specific set of parameters and agency';
comment on column at_rating.rating_code       is 'Synthetic key';
comment on column at_rating.source_agency     is 'Rating table source, office or agency name';
comment on column at_rating.rating_parms_code is 'Foreign key to the set of parameters';
comment on column at_rating.indep_parm_count  is 'Number of independent variables in the set of parameters(1 or 2)';
comment on column at_rating.indep_rounding_1  is '10-digit USGS style rounding string for the first independent parameter';
comment on column at_rating.indep_rounding_2  is '10-digit USGS style rounding string for the second independent parameter';
comment on column at_rating.dep_rounding      is '10-digit USGS style rounding string for the dependent parameter';


/*-----------------*/
/*  AT_RATING_LOC  */
/*-----------------*/


create table at_rating_loc
( rating_loc_code       number(10), 
  rating_code           number(10)  not null,
  location_code         number(10)  not null,
  source_version        varchar2(16), 
  auto_update_flag      varchar2(1) not null,
  auto_active_flag      varchar2(1) not null,
  auto_migrate_ext_flag varchar2(1) not null,
  agency_alias          varchar2(32),
  description           varchar2(200));

alter table at_rating_loc add constraint at_rating_loc_pk 
primary key (rating_loc_code);

alter table at_rating_loc add constraint at_rating_loc_fk1
foreign key (rating_code) references at_rating;

alter table at_rating_loc add constraint at_rating_loc_fk2
foreign key (location_code) references at_physical_location;

alter table at_rating_loc add constraint at_rating_loc_ck1
check (auto_update_flag in ('T','F'));

alter table at_rating_loc add constraint at_rating_loc_ck2
check (auto_active_flag in ('T','F'));

alter table at_rating_loc add constraint at_rating_loc_ck3
check (auto_migrate_ext_flag in ('T','F'));

create unique index at_rating_loc_ak1 on at_rating_loc
( rating_code, 
  location_code,
  source_version);

comment on table  at_rating_loc                is 'Defines metadata specific to a rating template and location';
comment on column at_rating_loc.rating_code    is 'Foreign key to the rating template';
comment on column at_rating_loc.location_code  is 'Foreign key to the cwms location to which this rating applies. A "0" indicates that the rating is not associated with a particilar location';
comment on column at_rating_loc.source_version is 'Used to identify multiple sets of ratings for a particular template and location "test"';
comment on column at_rating_loc.auto_update_flag      is '="T" tells the loading application to automatically retrieve and loaded new ratings';
comment on column at_rating_loc.auto_active_flag      is '="T" to automatically mark newly loaded curves as active';
comment on column at_rating_loc.auto_migrate_ext_flag is '="T" to automatically migrate prior rating extensions to a newly loaded curve';
comment on column at_rating_loc.agency_alias          is 'e.g., USGS Station No';
comment on column at_rating_loc.description           is 'General information pertinent to this rating template and location';


/*-------------------------*/
/* CWMS_RATING_INTERPOLATE */
/*-------------------------*/


create table cwms_rating_interpolate
( interpolate_code  number(10),
  interpolate_id    varchar2(32) not null);

alter table cwms_rating_interpolate add constraint cwms_rating_interp_pk 
primary key (interpolate_code);

create unique index cwms_rating_interp_ak1 on cwms_rating_interpolate (interpolate_id);

comment on table  cwms_rating_interpolate                is 'Table of rating curve expansion functions';
comment on column cwms_rating_interpolate.interpolate_id is 'USGS "RATING EXPANSION" ("LOGARITHMIC")';

insert into cwms_rating_interpolate values (1,'Linear');
insert into cwms_rating_interpolate values (2,'Logarithmic');


/*-----------------*/
/*  AT_RATING_SPEC */
/*-----------------*/


create table at_rating_spec
( rating_spec_code  number(10),
  rating_loc_code   number(10)  not null,
  effective_date    date        not null,
  create_date       date        not null, 
  version           varchar2(8) not null,
  active_flag       char(1)     not null,
  interpolate_code  number(10),
  description       varchar2(2000));

alter table at_rating_spec add constraint at_rating_spec_pk 
primary key (rating_spec_code);

alter table at_rating_spec add constraint at_rating_spec_fk1 
foreign key (rating_loc_code) references at_rating_loc
on delete cascade;

alter table at_rating_spec add constraint at_rating_spec_ck1
check (active_flag in ('T','F'));
 
create unique index at_rating_spec_ak1 on at_rating_spec
( rating_loc_code, 
  effective_date);  

comment on table  at_rating_spec                  is 'Defines metadata for a specific rating table';
comment on column at_rating_spec.rating_spec_code is 'Synthetic key';
comment on column at_rating_spec.rating_loc_code  is 'Foreign key to the rating template at a location';
comment on column at_rating_spec.effective_date   is 'The date on/after which this rating SHOULD be used';
comment on column at_rating_spec.create_date      is 'The date the rating table was stored in the database';
comment on column at_rating_spec.active_flag      is '="T" if the rating is to be used, else "F"';
comment on column at_rating_spec.interpolate_code is 'Foreign key to the interpolation type ("Logarithmic")';
comment on column at_rating_spec.description      is 'General information specific to this rating table. For USGS RDB files, the header is put here';


/*--------------------------*/
/* AT_RATING_EXTENSION_SPEC */
/*--------------------------*/


create table at_rating_extension_spec
( rating_extension_code  number(10),
  rating_spec_code       number(10)  not null,
  effective_date         date        not null,
  active_flag            varchar2(1) not null);

alter table at_rating_extension_spec add constraint at_rating_extension_spec_pk
primary key (rating_extension_code);
  
alter table at_rating_extension_spec add constraint at_rating_extension_spec_fk1
foreign key (rating_spec_code) references at_rating_spec 
on delete cascade;

alter table at_rating_extension_spec add constraint at_rating_extension_spec_ck1
check (active_flag in ('T','F'));

create unique index at_rating_extension_spec_ak1 on at_rating_extension_spec
( rating_spec_code,
  effective_date);

comment on table  at_rating_extension_spec                       is 'Associates extensions with a specific rating table';
comment on column at_rating_extension_spec.rating_extension_code is 'Synthetic key';
comment on column at_rating_extension_spec.rating_spec_code      is 'The curve this extension applies to';
comment on column at_rating_extension_spec.effective_date        is 'The date on/after which this extension should be used';
comment on column at_rating_extension_spec.active_flag           is '="T" if the extension is to be used, else "F"';


/*-----------------------------*/
/*  AT_RATING_EXTENSION_VALUE  */
/*-----------------------------*/


create table at_rating_extension_value
( rating_extension_code   number(10), 
  x                       number      not null,
  y                       number      not null,
  constraint              at_rating_extension_value_pk
  primary key            (rating_extension_code,x))
organization index;

alter table at_rating_extension_value add constraint at_rating_extension_value_fk1
foreign key (rating_extension_code) references at_rating_extension_spec
on delete cascade;

comment on table at_rating_extension_value is 'Extends the top or bottom of a rating curve';


/*-----------------*/
/* AT_RATING_CURVE */
/*-----------------*/


create table at_rating_curve
( rating_curve_code  number(10),
  rating_spec_code   number(10) not null,
  indep_parm_number  number(4)  not null,
  indep_parm_value   number);

alter table at_rating_curve add constraint at_rating_curve_pk
primary key (rating_curve_code);

alter table at_rating_curve add constraint at_rating_curve_fk1
foreign key (rating_spec_code) references at_rating_spec 
on delete cascade;

create unique index at_rating_curve_ak1 on at_rating_curve 
( rating_spec_code,
  indep_parm_number,
  indep_parm_value);

comment on table  at_rating_curve                   is 'Associates rating curves with a specific rating table';
comment on column at_rating_curve.rating_curve_code is 'Synthetic key';
comment on column at_rating_curve.rating_spec_code  is 'Foreign key to a specific rating table';
comment on column at_rating_curve.indep_parm_number is '=1..n, where n=the number of independent parmameters';
comment on column at_rating_curve.indep_parm_value  is 'The value of the second independent parameter for this curve, NULL if INDEP_PARM_NUMBER=1';


/*-----------------*/
/* AT_RATING_VALUE */
/*-----------------*/


create table at_rating_value
( rating_curve_code  number(10),
  x                  number,
  y                  number       not null,
  stor               varchar2(1), 
  constraint         at_rating_value_pk
  primary key       (rating_curve_code,x))
organization index;

alter table at_rating_value add constraint at_rating_value_fk1
foreign key (rating_curve_code) references at_rating_curve
on delete cascade;

alter table at_rating_value add constraint at_rating_value_ck1
check (stor is null or stor = '*');

comment on table  at_rating_value      is 'Rating table values. For USGS RDB tables, this is the expanded, shifted rating table';
comment on column at_rating_value.stor is '"*"=USGS STOR point, else NULL';


/*-------------------*/
/* DIRECTORY OBJECTS */
/*-------------------*/


create or replace directory rdbfiles   as '/usr1/dba/oracle/rdbfiles';


/*----------------*/
/* ET_RDB_COMMENT */
/*----------------*/

--drop table et_rdb_comment;

create table et_rdb_comment
( line varchar2(255) )
organization external
( type oracle_loader
  default directory rdbfiles
  access parameters
    ( records delimited by newline
      nologfile 
      nobadfile
      nodiscardfile 
      load when (1:1)='#'
      fields terminated by '\n' rtrim
      missing field values are null
    )
  location ('WYNW.rdb')
)
reject limit unlimited;


/*** ET_RDB_VALUE ***/


--drop table et_rdb_value;

create table et_rdb_value
( x      number,
  shift  number,
  y      number,
  stor   varchar2(1) )
organization external
( type oracle_loader
  default directory rdbfiles
  access parameters
    ( records delimited by newline
      nobadfile nologfile nodiscardfile
      fields terminated by '\t' rtrim
      missing field values are null
    )
  location ('WYNW.rdb')
)
reject limit unlimited;


/*-----------*/
/* AV_RATING */
/*-----------*/


--- Note: This would be easier if 
---       MV_CWMS_TS_ID contained the PARAMETER_CODE 

create or replace view av_rating as
with pc as 
  ( select parameter_code, 
           base_parameter_id||nvl2(sub_parameter_id,'-'||sub_parameter_id,null) parameter_id
    from   at_parameter inner join cwms_base_parameter using (base_parameter_code) )
select r.rating_code,
       r.db_office_code,
       r.source_agency, 
       (select parameter_id from pc where parameter_code = p.indep_parm_code_1) indep_parm_1, 
       (select parameter_id from pc where parameter_code = p.indep_parm_code_2) indep_parm_2, 
       (select parameter_id from pc where parameter_code = p.dep_parm_code)     dep_parm, 
       r.indep_rounding_1,
       r.indep_rounding_2,
       r.dep_rounding
from   at_rating r inner join at_rating_parameters    p using (rating_parms_code);


/*----------*/
/* AV_CURVE */
/*----------*/


create or replace view av_curve as
with pc as 
  ( select parameter_code, 
           base_parameter_id||nvl2(sub_parameter_id,'-'||sub_parameter_id,null) parameter_id
    from   at_parameter inner join cwms_base_parameter using (base_parameter_code) )
select rating_code,
       r.db_office_code,
       r.source_agency, 
       l.source_version,
       (select parameter_id from pc where parameter_code = p.indep_parm_code_1) indep_parm_1, 
       (select parameter_id from pc where parameter_code = p.indep_parm_code_2) indep_parm_2, 
       (select parameter_id from pc where parameter_code = p.dep_parm_code)     dep_parm, 
       r.indep_rounding_1,
       r.indep_rounding_2,
       r.dep_rounding,
       rating_loc_code,
       l.location_code, 
       (case when l.location_code = 0 then null
        else (select base_location_id||nvl2(sub_location_id,'-'||sub_location_id,null) 
              from   at_base_location inner join at_physical_location using (base_location_code)
              where  location_code = l.location_code)
        end) location_id,      
       l.auto_update_flag, 
       l.auto_active_flag, 
       l.auto_migrate_ext_flag, 
       l.agency_alias,
       rating_spec_code,
       s.effective_date,
       s.create_date, 
       s.version,
       s.active_flag,
       i.interpolate_id,
       rating_curve_code,
       c.indep_parm_number,
       c.indep_parm_value
from   at_rating r inner join at_rating_parameters    p using (rating_parms_code)
                    left join at_rating_loc           l using (rating_code)
                    left join at_rating_spec          s using (rating_loc_code)
                    left join cwms_rating_interpolate i using (interpolate_code)
                    left join at_rating_curve         c using (rating_spec_code)
where c.indep_parm_number = 1;       

 
/*
/*** MV_CURVE ***/



create materialized view mv_curve 
using no index
refresh complete on demand
enable query rewrite
as 
select rating_loc_code      loc_code,
       s.effective_date     base_date,
       ss.effective_date    shift_date, 
       s.active_flag        active, 
       ss.active_flag       shift_active, 
       ss.transition_flag   transition,  
       rating_code,
       location_code,
       s.version, 
       rating_spec_code     spec_code, 
       c.rating_curve_code  curve_code, 
       ss.rating_shift_code shift_code, 
       auto_load_flag       auto_load, 
       auto_active_flag     auto_active 
from   at_rating_loc l inner join at_rating_spec          s using (rating_loc_code)
                        left join at_rating_shift_spec   ss using (rating_spec_code)
                        left join at_rating_curve         c using (rating_spec_code)
where indep_parm_number = 1                    
order by loc_code, base_date, shift_date; 

CREATE UNIQUE INDEX MV_CURVE_PK ON MV_CURVE
(LOC_CODE, BASE_DATE, SHIFT_DATE, SPEC_CODE, CURVE_CODE, 
SHIFT_CODE)
LOGGING
TABLESPACE CWMS_20DATA
NOPARALLEL;
--alter table mv_curve add constraint mv_curve_pk 
--primary key (loc_code, base_date, shift_date, spec_code, curve_code, shift_code);
--/
*/