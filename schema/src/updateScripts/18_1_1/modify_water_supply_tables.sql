-----------------------------------
-- modify AT_WATER_USER_CONTRACT --
-----------------------------------
alter table at_water_user_contract drop constraint at_water_user_contract_ck1;
alter table at_water_user_contract drop constraint at_water_user_contract_ck2;

create or replace trigger at_water_user_contract_t01
for insert or update of pump_out_location_code, pump_out_below_location_code, pump_in_location_code
on at_water_user_contract
compound trigger

   type l_pumps_t is table of boolean index by varchar2(16);
   l_pumps l_pumps_t;

   before statement is
   begin
      for rec in (select pump_out_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_location_code is not null
                  union all
                  select pump_out_below_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_below_location_code is not null
                  union all
                  select pump_in_location_code as pump_code
                    from at_water_user_contract
                   where pump_in_location_code is not null
                 )
      loop
         l_pumps(to_char(rec.pump_code)) := true;
      end loop;
   end before statement;

   before each row is
   begin
      if :new.pump_out_location_code       = :new.pump_out_below_location_code or
         :new.pump_out_location_code       = :new.pump_in_location_code        or
         :new.pump_out_below_location_code = :new.pump_in_location_code
      then
         cwms_err.raise('ERROR', 'Water supply contract cannot have same pump in mulitple locations');
      end if;
      -----------------------
      -- pump_out_location --
      -----------------------
      if :new.pump_out_location_code is not null then
         if l_pumps.exists(:new.pump_out_location_code) and :new.pump_out_location_code != nvl(:old.pump_out_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump out location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_location_code)) := true;
         end if;
      end if;
      -----------------------------
      -- pump_out_below_location --
      -----------------------------
      if :new.pump_out_below_location_code is not null then
         if l_pumps.exists(:new.pump_out_below_location_code) and :new.pump_out_below_location_code != nvl(:old.pump_out_below_location_code, 0)  then
            cwms_err.raise('ERROR', 'Pump out below location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_below_location_code)) := true;
         end if;
      end if;
      ----------------------
      -- pump_in_location --
      ----------------------
      if :new.pump_in_location_code is not null then
         if l_pumps.exists(:new.pump_in_location_code) and :new.pump_in_location_code != nvl(:old.pump_in_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump in location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_in_location_code)) := true;
         end if;
      end if;
   end before each row;

end at_water_user_contract_t01;
/
-------------------------------------------
-- modify AT_WAT_USR_CONTRACT_ACCOUNTING --
-------------------------------------------
create table pump_location_changes as
   select distinct
          wuca.pump_location_code,
          o.office_id,
          bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
          lk.location_kind_id
     from at_wat_usr_contract_accounting wuca,
          at_physical_location pl,
          at_base_location  bl,
          cwms_office o,
          cwms_location_kind lk
    where pl.location_code = wuca.pump_location_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code
      and lk.location_kind_code = pl.location_kind
      and pump_location_code not in (select pump_location_code from at_pump)
    order by 2, 3;

declare
   l_pump_kind_code integer;
begin
   select location_kind_code into l_pump_kind_code from cwms_location_kind where location_kind_id = 'PUMP';
   for rec in (select * from pump_location_changes) loop
      dbms_output.put_line(rec.pump_location_code||':'||rec.office_id||'/'||rec.location_id);
      begin
         insert into at_stream_location (location_code) values (rec.pump_location_code);
      exception
         when dup_val_on_index then null;
      end;
      insert into at_pump values (rec.pump_location_code, 'Auto added from update script');
      update at_physical_location set location_kind = l_pump_kind_code where location_code = rec.pump_location_code;
   end loop;
end;
/

alter table at_wat_usr_contract_accounting drop constraint at_wat_usr_contr_accting_fk3;
alter table at_wat_usr_contract_accounting add constraint at_wat_usr_contr_accting_fk3 foreign key (pump_location_code) references at_pump(pump_location_code);
