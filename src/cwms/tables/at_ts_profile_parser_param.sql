create table at_ts_profile_parser_param(
   location_code       number(14,0) not null,
   key_parameter_code  number(14,0) not null,
   parameter_code      number(14,0) not null,
   parameter_unit      number(14,0) not null,
   parameter_field     number(3,0),
   parameter_col_start number(3,0),
   parameter_col_end   number(3,0),
   constraint at_ts_profile_parser_param_pk  primary key (location_code, key_parameter_code, parameter_code) using index,
   constraint at_ts_profile_parser_param_fk1 foreign key (location_code, key_parameter_code) references at_ts_profile_parser (location_code, key_parameter_code),
   constraint at_ts_profile_parser_param_fk2 foreign key (parameter_code) references at_parameter (parameter_code),
   constraint at_ts_profile_parser_param_fk3 foreign key (parameter_unit) references cwms_unit (unit_code)
);

comment on table  at_ts_profile_parser_param is 'Holds information about columns and units of time series profile parameters in a parser source';
comment on column at_ts_profile_parser_param.location_code       is 'The location that the profile is for';
comment on column at_ts_profile_parser_param.key_parameter_code  is 'The key parameter that other parameters in the profile are associated with';
comment on column at_ts_profile_parser_param.parameter_code      is 'The profile parameter';
comment on column at_ts_profile_parser_param.parameter_unit      is 'The unit of the profile parameter';
comment on column at_ts_profile_parser_param.parameter_field     is 'The 1-based field number in the parser containing the profile parameter (null if not delimited)';
comment on column at_ts_profile_parser_param.parameter_col_start is 'The 1-based column in the parser that this parameter field starts (null if delimited)';
comment on column at_ts_profile_parser_param.parameter_col_end   is 'The 1-based column in the parser that this parameter field ends (null if delimited)';

