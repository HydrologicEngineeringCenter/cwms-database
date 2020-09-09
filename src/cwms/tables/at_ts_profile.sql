create table at_ts_profile(
   location_code        number(10,0) not null,
   key_parameter_code   number(10,0) not null,
   reference_ts_code    number(10,0),
   description          varchar2(256),
   constraint at_ts_profile_pk  primary key (location_code, key_parameter_code) using index,
   constraint at_ts_profile_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_ts_profile_fk2 foreign key (key_parameter_code) references at_parameter (parameter_code),
   constraint at_ts_profile_fk3 foreign key (reference_ts_code) references at_cwms_ts_spec (ts_code)
);

comment on table  at_ts_profile is 'Holds information about time series profiles';
comment on column at_ts_profile.location_code      is 'The location that the profile is for';
comment on column at_ts_profile.key_parameter_code is 'The key parameter that other parameters in the profile are associated with';
comment on column at_ts_profile.reference_ts_code  is 'The time series, if any, used to transform the key parameter into the parameter of the time seires';
comment on column at_ts_profile.description        is 'The description of the profile';

