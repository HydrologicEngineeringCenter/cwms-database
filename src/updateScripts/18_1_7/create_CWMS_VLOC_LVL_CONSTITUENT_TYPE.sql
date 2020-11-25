create table CWMS_VLOC_LVL_CONSTITUENT_TYPE (
   constituent_type varchar2(16) primary key,
   constraint cwms_vloc_lvl_const_type_ck check (constituent_type in ('LOCATION_LEVEL','RATING','TIME_SERIES','FORMULA'))
);
comment on table  CWMS_VLOC_LVL_CONSTITUENT_TYPE is 'Holds valid constiuent types for virtual location levels';
comment on column CWMS_VLOC_LVL_CONSTITUENT_TYPE.constituent_type is 'The valid constituent types';
commit;
insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('LOCATION_LEVEL');
insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('RATING');
insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('TIME_SERIES');
insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('FORMULA');
commit;

