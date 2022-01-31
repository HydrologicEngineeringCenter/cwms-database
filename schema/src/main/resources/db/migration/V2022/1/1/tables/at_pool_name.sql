--drop table at_pool_name;
create table at_pool_name(
   pool_name_code integer,
   office_code    integer,
   pool_name      varchar2(32),
   constraint     at_pool_name_pk primary key (pool_name_code),
   constraint     at_pool_name_fk foreign key (office_code) references cwms_office (office_code)
) tablespace cwms_20at_data;  

comment on table  at_pool_name                is 'Holds pool name definitions';
comment on column at_pool_name.pool_name_code is 'Synthetic key';
comment on column at_pool_name.office_code    is 'Office that owns the pool name ';
comment on column at_pool_name.pool_name      is 'Name of pool';

create unique index at_pool_name_idx1 on at_pool_name (office_code, upper(pool_name));

declare
   cwms_pool_names str_tab_t;
begin
   cwms_pool_names := str_tab_t(
      'Dead',
      'Inactive',
      'Drought',
      'Minor Drought',
      'Major Drought',
      'Conservation',
      'Normal',
      'Power',
      'Navigation',
      'Flood',
      'Minor Flood',
      'Major Flood',
      'Exclusive Flood',
      'Multi-Purpose',
      'Surcharge'
   );
   for i in 1..cwms_pool_names.count loop
      insert into at_pool_name values (i, 53, cwms_pool_names(i));
   end loop;
end;
/

