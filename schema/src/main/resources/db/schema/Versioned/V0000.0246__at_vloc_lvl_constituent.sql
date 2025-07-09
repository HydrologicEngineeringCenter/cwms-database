create table at_vloc_lvl_constituent (
   location_level_code         number(14,0)  not null,
   constituent_abbr            varchar2(4)   not null,
   constituent_type            varchar2(16)  not null,
   constituent_name            varchar2(404) not null,
   constituent_attribute_id    varchar2(92),
   constituent_attribute_value number,
   constraint at_vloc_lvl_constituent_pk  primary key (location_level_code, constituent_abbr) using index,
   constraint at_vloc_lvl_constituent_fk1 foreign key (constituent_type) references cwms_vloc_lvl_constituent_type (constituent_type),
   constraint at_vloc_lvl_constituent_ck1 check (upper(constituent_abbr) = constituent_abbr)
);

comment on table at_vloc_lvl_constituent is 'Holds constituent pieces for virtual location levels';
comment on column at_vloc_lvl_constituent.location_level_code         is 'References the virtual location level (FK AT_VIRTUAL_LOCATION_LEVEL.LOCATION_LEVEL_CODE)';
comment on column at_vloc_lvl_constituent.constituent_abbr            is 'Label used for this constituent in AT_VIRTUAL_LOCATION_LEVEL.CONSTITUENT_CONNECTIONS';
comment on column at_vloc_lvl_constituent.constituent_type            is 'The constituent type (FK to CWMS_VIRT_LOC_LVL_CONST_TYPE.CONSTITUENT_TYPE)';
comment on column at_vloc_lvl_constituent.constituent_name            is 'The database identifier of the constituent (ts_id, rating_spec, etc...) or formula text for FORMULA constituents';
comment on column at_vloc_lvl_constituent.constituent_attribute_id    is 'The level attribute for LOCATION_LEVEL constituents';
comment on column at_vloc_lvl_constituent.constituent_attribute_value is 'The level attribute value for LOCATION_LEVEL constituents';
