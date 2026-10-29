create table at_ts_display_units(
   ts_code      number(14,0) not null,
   unit_system  varchar2(2) not null,
   unit_code    number(14,0) not null,
   constraint at_ts_display_units_pk primary key (ts_code, unit_system),
   constraint at_ts_display_units_fk1 foreign key (ts_code)
      references at_cwms_ts_spec (ts_code) on delete cascade,
   constraint at_ts_display_units_fk2 foreign key (unit_code)
      references cwms_unit (unit_code),
   constraint at_ts_display_units_ck1 check (unit_system in ('EN', 'SI'))
);

comment on table at_ts_display_units is 'Persistent time series display units, shared by all time series groups';
comment on column at_ts_display_units.ts_code is 'Time series whose display units are overridden';
comment on column at_ts_display_units.unit_system is 'Requested display unit system (EN or SI)';
comment on column at_ts_display_units.unit_code is 'Preferred display unit; does not change the storage unit';

-- Use the same write privilege guard as other time series metadata tables.
create or replace trigger st_ts_display_units
   before delete or insert or update on at_ts_display_units
declare
   l_priv varchar2(16);
begin
   l_priv := sys_context('CWMS_ENV', 'CWMS_PRIVILEGE');
   if (l_priv is null or l_priv <> 'CAN_WRITE')
      and user not in ('SYS', '&&cwms_schema', upper('&&builduser')) then
      cwms_err.raise('NO_WRITE_PRIVILEGE');
   end if;
end;
/
