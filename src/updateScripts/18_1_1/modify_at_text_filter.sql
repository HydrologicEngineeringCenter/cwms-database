------------------------------------------------------------------------------------------------
-- inserts column configuration_code integer default 1 between office_code and text_filter_id --
------------------------------------------------------------------------------------------------
create table at_text_filter_tmp as select * from at_text_filter;

alter table at_text_filter_element drop constraint at_text_filter_element_fk1;
drop table at_text_filter;

create table at_text_filter (
   text_filter_code   integer,
   office_code        integer,
   configuration_code integer default 1,
   text_filter_id     varchar2(32),
   is_regex           varchar2(1),
   regex_flags        varchar2(4),
   description        varchar2(256),
   constraint at_text_filter_pk  primary key (text_filter_code),
   constraint at_text_filter_fk1 foreign key (configuration_code) references at_configuration (configuration_code),
   constraint at_text_filter_ck1 check (trim(text_filter_id) = text_filter_id)
) tablespace cwms_20at_data
/

comment on table  at_text_filter is 'Holds text filter definitions';
comment on column at_text_filter.text_filter_code   is 'Synthetic key';
comment on column at_text_filter.office_code        is 'Foreign key to office that owns this text filter';
comment on column at_text_filter.configuration_code is 'Foreign key to configuration for this text filter';
comment on column at_text_filter.text_filter_id     is 'The text identifier (name) of this text filter';
comment on column at_text_filter.is_regex           is 'Flag (T/F) specifying whether this text filter uses regular expressions (''F'' = uses glob-style wildcards)';
comment on column at_text_filter.regex_flags        is 'Regex flags (match parameter) for all elements (overridden by individual element flags)';
comment on column at_text_filter.description        is 'Descriptive text about text filter';

create unique index at_text_filter_u1 on at_text_filter(office_code, upper(text_filter_id)) tablespace cwms_20at_data;

insert
  into at_text_filter (
       text_filter_code, office_code, text_filter_id, is_regex, regex_flags, description)
select text_filter_code, office_code, text_filter_id, is_regex, regex_flags, description
  from at_text_filter_tmp;

alter table at_text_filter_element add constraint at_text_filter_element_fk1 foreign key (text_filter_code) references at_text_filter (text_filter_code);

drop table at_text_filter_tmp;

