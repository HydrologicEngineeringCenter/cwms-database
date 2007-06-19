/*** CWMS v2.0 ***/



declare
   type id_array_t is table of varchar2(32);
   table_names id_array_t := id_array_t(
      'cwms_rating_type',
      'cwms_rating_interpolate',
      'at_rating',
      'at_rating_parameters',
      'table at_rating_versions',
      'at_rating_loc',
      'at_rating_extension_spec',
      'at_rating_extension_value',
      'at_rating_spec',
      'at_rating_shift_spec',
      'at_rating_shift_value',
      'at_rating_curve',
      'at_rating_value',
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

/*** CWMS_RATING_TYPE ***/


--alter table at_rating drop constraint at_rating_fk1;

--drop table cwms_rating_type;

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


--alter table at_rating drop constraint at_rating_fk2;		

--drop table cwms_rating_interpolate;

create table cwms_rating_interpolate
( interpolate_code  number(10),
  interpolate_id    varchar2(16) not null);

alter table cwms_rating_interpolate add constraint cwms_rating_interp_pk 
primary key (interpolate_code);

create unique index cwms_rating_interp_ak1 on cwms_rating_interpolate (interpolate_id);

comment on table  cwms_rating_interpolate                is 'Table of rating curve expansion functions';
comment on column cwms_rating_interpolate.interpolate_id is 'USGS "RATING EXPANSION" ("LOGARITHMIC")';

insert into cwms_rating_interpolate values (1,'Linear');
insert into cwms_rating_interpolate values (2,'Logarithmic');


/*** AT_RATING ***/


--alter table at_rating_parameters drop constraint at_rating_parms_fk1;
--alter table at_rating_loc        drop constraint at_rating_loc_fk1;

--drop table at_rating; 

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
comment on column at_rating.interpolate_code is 'Foreign key to the interpolation type ("Logarithmic")';
comment on column at_rating.indep_parm_count is 'Number of independent variables (1 or 2)';


/*** AT_RATING_PARMETERS ***/


--alter table at_rating_versions drop constraint at_rating_versions_fk1;

--drop table at_rating_parameters;


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

alter table at_rating_parameters add constraint at_rating_parms_fk2 
foreign key (indep_parm_code_1) references at_parameter(parameter_code);

alter table at_rating_parameters add constraint at_rating_parms_fk3 
foreign key (indep_parm_code_2) references at_parameter(parameter_code);

alter table at_rating_parameters add constraint at_rating_parms_fk4 
foreign key (dep_parm_code) references at_parameter(parameter_code);
 
create unique index at_rating_parms_ak1 on at_rating_parameters
( rating_code, 
  indep_parm_code_1, 
  indep_parm_code_2,
  dep_parm_code);

comment on table at_rating_parameters is 'Defines a set of parameters for a rating family';


/*** AT_RATING_VERSIONS ***/


--drop table at_rating_versions;

create table at_rating_versions
( rating_versions_code number(10),
  rating_parms_code    number(10)    not null,
  indep_version_1      varchar2(32)  not null,
  indep_version_2      varchar2(32),
  dep_version          varchar2(32)  not null,
  constraint           at_rating_versions_pk primary key (rating_versions_code));

alter table at_rating_versions add constraint at_rating_versions_fk1 
foreign key (rating_parms_code) references at_rating_parameters
on delete cascade;

create unique index at_rating_versions_ak1 on at_rating_versions
( rating_parms_code,
  indep_version_1,
  indep_version_2,
  dep_version);

comment on table  at_rating_versions                   is 'Defines a Version set for a specific parameter set for a rating family';
comment on column at_rating_versions.rating_parms_code is 'A specific parameter set for a general rating family';
comment on column at_rating_versions.indep_version_1   is 'First independent parameter version for automatic association';
comment on column at_rating_versions.indep_version_2   is 'Second independent parameter (use zero for null value)';
comment on column at_rating_versions.dep_version       is 'Dependent parameter version for automatic association';


/***  AT_RATING_LOC  ***/


--alter table at_rating_extension_spec drop constraint at_rating_extension_spec_fk1;
--alter table at_rating_spec      drop constraint at_rating_spec_fk1;

--drop table at_rating_loc;

create table at_rating_loc
( rating_loc_code    number(10), 
  rating_code        number(10)  not null,
  location_code      number(10)  not null,
  auto_load_flag     char(1)     not null,
  auto_active_flag   char(1)     not null,
  filename           varchar2(32),
  description        varchar2(160));

alter table at_rating_loc add constraint at_rating_loc_pk 
primary key (rating_loc_code);

alter table at_rating_loc add constraint at_rating_loc_fk1
foreign key (rating_code) references at_rating;

alter table at_rating_loc add constraint at_rating_loc_fk2
foreign key (location_code) references at_physical_location;

alter table at_rating_loc add constraint at_rating_loc_ck1
check (auto_load_flag in ('T','F'));

alter table at_rating_loc add constraint at_rating_loc_ck2
check (auto_active_flag in ('T','F'));

create unique index at_rating_loc_ak1 on at_rating_loc
( rating_code, 
  location_code);

comment on table  at_rating_loc               is 'Defines the metadata for a rating family at a location';
comment on column at_rating_loc.rating_code   is 'Foreign key to rating family';
comment on column at_rating_loc.location_code is 'Foreign key to the cwms location to which this rating applies';
comment on column at_rating_loc.auto_load_flag     is '="T" to automatically load new curves and shifts when they become available';
comment on column at_rating_loc.auto_active_flag   is '="T" to automatically mark newly loaded curves and shifts as active';
comment on column at_rating_loc.filename           is 'rating table filename (do we also need file type, "RDB" ?)';


/*** AT_RATING_EXTENSION_SPEC ***/


--alter table at_rating_extension_value drop constraint at_rating_extension_value_fk1;

--drop table at_rating_extension_spec;

create table at_rating_extension_spec
( rating_extension_code  number(10),
  rating_loc_code        number(10) not null,
  effective_date         date       not null,
  active_flag            char(1)    not null);

alter table at_rating_extension_spec add constraint at_rating_extension_spec_pk
primary key (rating_extension_code);
  
alter table at_rating_extension_spec add constraint at_rating_extension_spec_fk1
foreign key (rating_loc_code) references at_rating_loc 
on delete cascade;

alter table at_rating_extension_spec add constraint at_rating_extension_spec_ck1
check (active_flag in ('T','F'));

create unique index at_rating_extension_spec_ak1 on at_rating_extension_spec
( rating_loc_code,
  effective_date);

comment on table  at_rating_extension_spec                       is 'Associates extensions with a specific rating table';
comment on column at_rating_extension_spec.rating_extension_code is 'Synthetic key';
comment on column at_rating_extension_spec.rating_loc_code       is 'The location this extension applies to';
comment on column at_rating_extension_spec.effective_date        is 'The date on/after which this extension should be used';
comment on column at_rating_extension_spec.active_flag           is '="T" if the extension is to be used, else "F"';


/***  AT_RATING_EXTENSION_VALUE  ***/


--drop table at_rating_extension_value;

create table at_rating_extension_value
( rating_extension_code   number(10), 
  x                       number      not null,
  y                       number      not null);

alter table at_rating_extension_value add constraint at_rating_extension_value_pk 
primary key (rating_extension_code,x);

alter table at_rating_extension_value add constraint at_rating_extension_value_fk1
foreign key (rating_extension_code) references at_rating_extension_spec
on delete cascade;

comment on table at_rating_extension_value is 'Extends the top or bottom of the rating curves for a rating family at a location';


/***  AT_RATING_SPEC ***/


--alter table at_rating_shift_spec drop constraint at_rating_shift_spec_fk1;
--alter table at_rating_curve      drop constraint at_rating_curve_fk1;

--drop table at_rating_spec;

create table at_rating_spec
( rating_spec_code  number(10),
  rating_loc_code   number(10)  not null,
  effective_date    date        not null,
  create_date       date        not null, 
  version           varchar2(8) not null,
  active_flag       char(1)     not null,
  indep_rounding_1   varchar2(10),
  indep_rounding_2   varchar2(10),
  dep_rounding       varchar2(10));

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

comment on table  at_rating_spec                  is 'Defines a specific rating table';
comment on column at_rating_spec.rating_spec_code is 'Synthetic key';
comment on column at_rating_spec.rating_loc_code  is 'Foreign key to rating family at a location';
comment on column at_rating_spec.effective_date   is 'The date on/after which this rating SHOULD be used';
comment on column at_rating_spec.create_date      is 'The date the rating table was stored in the database';
comment on column at_rating_spec.active_flag      is '="T" if the rating is to be used, else "F"';
comment on column at_rating_spec.version          is 'The base rating table version; the RATING ID in the USGS rdb file " 9.0"';
comment on column at_rating_spec.indep_rounding_1 is '10-digit USGS rounding code';
comment on column at_rating_spec.indep_rounding_2 is '10-digit USGS rounding code';
comment on column at_rating_spec.dep_rounding     is '10-digit USGS rounding code';


/*** AT_RATING_SHIFT_SPEC ***/


--alter table at_rating_shift_value drop constraint at_rating_shift_value_fk1;

--drop table at_rating_shift_spec;

create table at_rating_shift_spec
( rating_shift_code  number(10),
  rating_spec_code   number(10) not null,
  effective_date     date       not null,
  active_flag        char(1)    not null,
  transition_flag    char(1)    not null);

alter table at_rating_shift_spec add constraint at_rating_shift_spec_pk
primary key (rating_shift_code);
  
alter table at_rating_shift_spec add constraint at_rating_shift_spec_fk1
foreign key (rating_spec_code) references at_rating_spec 
on delete cascade;

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


/*** AT_RATING_SHIFT_VALUE ***/


--drop table at_rating_shift_value;

create table at_rating_shift_value
( rating_shift_code  number(10),
  stage              number,
  shift              number     not null,
  constraint         at_rating_shift_value_pk 
  primary key       (rating_shift_code, stage))
organization index;

alter table at_rating_shift_value add constraint at_rating_shift_value_fk1
foreign key (rating_shift_code) references at_rating_shift_spec 
on delete cascade;

comment on table  at_rating_shift_value       is 'Table of one or more shifts to be applied to a specific rating table';
comment on column at_rating_shift_value.stage is 'The value of INDEP_PARM_1 where this shift begins';
comment on column at_rating_shift_value.shift is 'The value to add to INDEP_PARM_1 before rating the value';


/*** AT_RATING_CURVE ***/


--alter table at_rating_value drop constraint at_rating_value_fk1;

--drop table at_rating_curve;

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
comment on column at_rating_curve.rating_spec_code  is 'Points to a specific rating table';
comment on column at_rating_curve.indep_parm_number is '=1..n, where n=the number of independent parmameters';
comment on column at_rating_curve.indep_parm_value  is 'The value of the second independent parameter for this curve, NULL if INDEP_PARM_NUMBER=1';


/*** AT_RATING_VALUE ***/


--drop table at_rating_value;

create table at_rating_value
( rating_curve_code  number(10),
  x                  number,
  y                  number       not null,
  stor               char(1), 
  constraint         at_rating_value_pk
  primary key       (rating_curve_code,x))
organization index;


-- alter table at_rating_value drop constraint at_rating_value_fk1;

alter table at_rating_value add constraint at_rating_value_fk1
foreign key (rating_curve_code) references at_rating_curve
on delete cascade;

alter table at_rating_value add constraint at_rating_value_ck1
check (stor is null or stor in ('*','E'));

comment on table  at_rating_value      is 'Table of expanded (base) rating table values';
comment on column at_rating_value.stor is '"*"=USGS STOR point, "E"=user Extension, else NULL';


/*** DIRECTORY OBJECTS ***/


create or replace directory rdbfiles   as '/usr1/dba/oracle/rdbfiles';


/*** ET_RDB_COMMENT ***/


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


/*** AV_RATING ***/

--- Note: This would be easier if 
---       MV_CWMS_TS_ID contained the PARAMETER_CODE 


create or replace view av_rating as
with pc as 
  ( select parameter_code, 
           base_parameter_id||nvl2(sub_parameter_id,'-'||sub_parameter_id,null) parameter_id
    from   at_parameter inner join cwms_base_parameter using (base_parameter_code) )
select r.db_office_code,
       rating_code,  
       r.source, 
       rating_type_code    type_code, 
       t.rating_type_id    type, 
       t.long_name,
       i.interpolate_id    interpolate, 
       r.description       rating_desc, 
       rating_parms_code   parms_code,
       r.indep_parm_count  parm_count,
       (select parameter_id from pc where parameter_code = p.indep_parm_code_1) indep_parm_1, 
       (select parameter_id from pc where parameter_code = p.indep_parm_code_2) indep_parm_2, 
       (select parameter_id from pc where parameter_code = p.dep_parm_code)     dep_parm, 
       v.indep_version_1,
       v.indep_version_2,
       v.dep_version,
       p.description       parm_desc
from   at_rating r inner join cwms_rating_type        t using (rating_type_code)
                   inner join cwms_rating_interpolate i using (interpolate_code)
                    left join at_rating_parameters    p using (rating_code) 
                    left join at_rating_versions      v using (rating_parms_code);


/*** AV_CURVE ***/


create or replace view av_curve as
select r.db_office_code,
       rating_code,  
       r.source, 
       rating_type_code     type_code, 
       t.rating_type_id     type, 
       i.interpolate_id     interpolate, 
       rating_loc_code      loc_code,
       l.location_code, 
       (select base_location_id||nvl2(sub_location_id,'-'||sub_location_id,null) 
        from   at_base_location inner join at_physical_location using (base_location_code)
        where  location_code = l.location_code) location_id, 
       l.auto_load_flag     auto_load, 
       l.auto_active_flag   auto_active, 
       l.filename, 
       l.description,
       rating_spec_code     spec_code, 
       s.effective_date     base_date,
       s.create_date, 
       s.version, 
       s.active_flag        active, 
       c.rating_curve_code  curve_code, 
       c.indep_parm_number  parm_number, 
       c.indep_parm_value   parm_value, 
       ss.rating_shift_code shift_code, 
       ss.effective_date    shift_date, 
       ss.active_flag       shift_active, 
       ss.transition_flag   transition  
from   at_rating r inner join cwms_rating_type        t using (rating_type_code)
                   inner join cwms_rating_interpolate i using (interpolate_code)
                    left join at_rating_loc           l using (rating_code)
                    left join at_rating_spec          s using (rating_loc_code)
                    left join at_rating_shift_spec   ss using (rating_spec_code)
                    left join at_rating_curve         c using (rating_spec_code)
where indep_parm_number = 1                    
order by source, type, location_id, base_date, shift_date;

 

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


alter table mv_curve add constraint mv_curve_pk 
primary key (loc_code, base_date, shift_date, spec_code, curve_code, shift_code);
/
