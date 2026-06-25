create table at_comp_outlet_conn (
   at_comp_outlet_conn_code number(14) primary key,
   compound_outlet_code     number(14) not null,
   outlet_location_code     number(14) not null,
   next_outlet_code         number(14),
   constraint at_comp_outlet_conn_fk1 foreign key (compound_outlet_code) references at_comp_outlet (compound_outlet_code),
   constraint at_comp_outlet_conn_fk2 foreign key (outlet_location_code) references at_outlet (outlet_location_code),
   constraint at_comp_outlet_conn_fk3 foreign key (next_outlet_code) references at_outlet (outlet_location_code),
   constraint at_comp_outlet_conn_ck1 check (outlet_location_code != nvl(next_outlet_code, 0))
) organization index
  tablespace cwms_20at_data
/

comment on table  at_comp_outlet_conn is 'Holds information about compound outlet connectivity';
comment on column at_comp_outlet_conn.at_comp_outlet_conn_code is 'Synthetic key';
comment on column at_comp_outlet_conn.compound_outlet_code     is 'References sequential outlet group';
comment on column at_comp_outlet_conn.outlet_location_code     is 'References outlet on the upstream side of the connection';
comment on column at_comp_outlet_conn.next_outlet_code         is 'References outlet on the downstream side of the connection (0 if outlet downstream-most in sequence)';

create unique index at_comp_outlet_conn_idx1 on at_comp_outlet_conn(compound_outlet_code, outlet_location_code, nvl(next_outlet_code, 0))
/
create index at_comp_outlet_conn_idx2 on at_comp_outlet_conn(outlet_location_code)
/

create or replace trigger at_comp_outlet_conn_tr1
   before insert
   on at_comp_outlet_conn
   referencing new as new old as old
   for each row
declare
   l_proj_code1 number(14);
   l_proj_code2 number(14);
begin
   select project_location_code
     into l_proj_code1
     from at_comp_outlet
    where compound_outlet_code = :new.compound_outlet_code;

   select project_location_code
     into l_proj_code2
     from at_outlet
    where outlet_location_code = :new.outlet_location_code;

   if l_proj_code1 != l_proj_code2 then
      cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
   end if;

   if :new.next_outlet_code is not null then
      select project_location_code
        into l_proj_code2
        from at_outlet
       where outlet_location_code = :new.next_outlet_code;

      if l_proj_code1 != l_proj_code2 then
         cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
      end if;
   end if;
end at_comp_outlet_conn_tr1;
/
