create table at_ts_profile_param(
   location_code        number(14,0) not null,
   key_parameter_code   number(14,0) not null,
   position             number(3,0)  not null,
   parameter_code       number(14,0) not null,
   constraint at_ts_profile_param_pk  primary key (location_code, key_parameter_code, position),
   constraint at_ts_profile_param_fk1 foreign key (location_code, key_parameter_code) references at_ts_profile (location_code, key_parameter_code),
   constraint at_ts_profile_param_fk2 foreign key (parameter_code) references at_parameter (parameter_code)
) organization index;
create unique index at_ts_profile_param_idx1 on at_ts_profile_param (location_code, key_parameter_code, parameter_code);

comment on table  at_ts_profile_param is 'Holds information about the parameters of time series profiles';
comment on column at_ts_profile_param.location_code      is 'The location that the profile is for';
comment on column at_ts_profile_param.key_parameter_code is 'The key parameter that other parameters in the profile are associated with';
comment on column at_ts_profile_param.position           is 'The 1-based ordered position of the prarameter in the profile';
comment on column at_ts_profile_param.parameter_code     is 'The profile parameter';

