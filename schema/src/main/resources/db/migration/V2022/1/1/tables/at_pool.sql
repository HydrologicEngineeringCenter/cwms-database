--drop table at_pool;
create table at_pool(
  pool_code      integer,
  pool_name_code integer not null,
  project_code   integer not null,
  clob_code      integer,
  attribute      number,
  bottom_level   varchar2(256) not null,
  top_level      varchar2(256) not null,
  description    varchar2(128),
  constraint at_pool_pk  primary key (pool_code),
  constraint at_pool_fk1 foreign key (pool_name_code) references at_pool_name (pool_name_code),
  constraint at_pool_fk2 foreign key (project_code) references at_project (project_location_code),
  constraint at_pool_fk3 foreign key (clob_code) references at_clob (clob_code)
) tablespace cwms_20at_data;

comment on table  at_pool                is 'Holds pool definitions for projects';
comment on column at_pool.pool_code      is 'Synthetic key';
comment on column at_pool.pool_name_code is 'Reference to pool name';
comment on column at_pool.project_code   is 'Reference to project';
comment on column at_pool.clob_code      is 'Reference to CLOB containing more (possibly structured) information';
comment on column at_pool.attribute      is 'Numeric attribute, most likely used for sorting';
comment on column at_pool.bottom_level   is 'Location level ID for bottom of pool (minus location portion)';
comment on column at_pool.top_level      is 'Location level ID for top of pool (minus location portion)';
comment on column at_pool.description    is 'Text description of pool';

create unique index at_pool_idx1 on at_pool(project_code, pool_name_code);
create unique index at_pool_idx2 on at_pool(pool_name_code, project_code);
create index        at_pool_idx3 on at_pool(project_code, upper(bottom_level));
create index        at_pool_idx4 on at_pool(upper(bottom_level), project_code);
create index        at_pool_idx5 on at_pool(project_code, upper(top_level));
create index        at_pool_idx6 on at_pool(upper(top_level), project_code);
create index        at_pool_idx7 on at_pool(project_code, nvl(attribute, -1e125));

create or replace trigger at_pool_t01
   before insert or update
   of bottom_level, top_level
   on at_pool
   for each row
declare
   l_rec  at_location_level%rowtype;
   l_text varchar2(64);
begin
   -----------------------------
   -- assert different levels --
   -----------------------------
   if :new.bottom_level = :new.top_level then
      cwms_err.raise('ERROR', 'Top and bottom levels cannot be the same');
   end if;
   -----------------------------------------------
   -- validate bottom level is 'Elev.Inst.0...' --
   -----------------------------------------------
   if instr(:new.bottom_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Bottom location level ID must start with ''Elev.Inst.0''');
   end if;
   --------------------------------------------
   -- validate top level is 'Elev.Inst.0...' --
   --------------------------------------------
   if instr(:new.top_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Top location level ID must start with ''Elev.Inst.0''');
   end if;
end at_pool_t01;
/

show errors


