create table at_ts_profile_instance(
   location_code        number(14,0) not null,
   key_parameter_code   number(14,0) not null,
   version_id           varchar2(32) not null,
   first_date_time      date not null,
   last_date_time       date not null,
   version_date         date not null,
   constraint at_ts_profile_instance_fk1 foreign key (location_code, key_parameter_code) references at_ts_profile (location_code, key_parameter_code)
);

create unique index at_ts_profile_instance_pk on at_ts_profile_instance(location_code, key_parameter_code, upper(version_id), first_date_time, version_date);

comment on table  at_ts_profile_instance is 'Holds information about the time series profile instances';
comment on column at_ts_profile_instance.location_code      is 'The location that the profile is for';
comment on column at_ts_profile_instance.key_parameter_code is 'The key parameter that other parameters in the profile are associated with';
comment on column at_ts_profile_instance.version_id         is 'The version (e.g., ''Raw'', ''Rev'') of the instance. Used for the version of the associated time series ids.';
comment on column at_ts_profile_instance.first_date_time    is 'The earliest timestamp of the profile instance';
comment on column at_ts_profile_instance.last_date_time     is 'The latest timestamp of the profile instance';
comment on column at_ts_profile_instance.version_date       is 'The version date of the instance and associated time series values';

