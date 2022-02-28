create table at_ts_profile_parser(
   location_code        number(14,0) not null,
   key_parameter_code   number(14,0) not null,
   time_field           number(3,0),
   time_in_two_fields   char(1),
   time_col_start       number(3,0),
   time_col_end         number(3,0),
   time_zone_code       number(14,0) not null,
   time_format          varchar2(32) not null,
   record_delimiter     varchar2(1)  not null,
   field_delimiter      varchar2(1),
   constraint at_ts_profile_parser_pk  primary key (location_code, key_parameter_code) using index,
   constraint at_ts_profile_parser_fk1 foreign key (location_code, key_parameter_code) references at_ts_profile (location_code, key_parameter_code)
);

comment on table  at_ts_profile_parser is 'Holds information about time series profiles in a parser source';
comment on column at_ts_profile_parser.location_code      is 'The location that the profile is for';
comment on column at_ts_profile_parser.key_parameter_code is 'The key parameter that other parameters in the profile are associated with';
comment on column at_ts_profile_parser.time_field         is 'The 1-based field number (or first of two adjacent fields) containing the timestamp (null if not delimited)';
comment on column at_ts_profile_parser.time_col_start     is 'The 1-based column in the parser that the timestamp field starts (null if delimited)';
comment on column at_ts_profile_parser.time_col_end       is 'The 1-based column in the parser that the timestamp field ends (null if delimited)';
comment on column at_ts_profile_parser.time_in_two_fields is '''T'' if the date and time are in adjacent fields (beginning with time_field), ''F'' if date and time are in same field';
comment on column at_ts_profile_parser.time_zone_code     is 'The time zone of the timestamp';
comment on column at_ts_profile_parser.time_format        is 'The Oracle date/time format model string for the timestamp (if timestamp is two adjacent fields, place a field delimiter between the date and time portions of the format)';
comment on column at_ts_profile_parser.record_delimiter   is 'The record delimiter character of the parser source (default = newline)';
comment on column at_ts_profile_parser.field_delimiter    is 'The field delimiter character of the parser source, if fields are delimited and not fixed width';
