drop trigger at_water_user_contract_ck1;
drop trigger at_water_user_contract_ck2;
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
      -----------------------
      -- pump_out_location --
      -----------------------
      if :new.pump_out_location_code is not null then
         if l_pumps.exists(:new.pump_out_location_code) then
            cwms_err.raise('ERROR', 'Pump is already used in a water supply contract');
         else
            l_pumps(to_char(:new.pump_out_location_code)) := true;
         end if;
      end if;
      -----------------------------
      -- pump_out_below_location --
      -----------------------------
      if :new.pump_out_below_location_code is not null then
         if l_pumps.exists(:new.pump_out_below_location_code) then
            cwms_err.raise('ERROR', 'Pump is already used in a water supply contract');
         else
            l_pumps(to_char(:new.pump_out_below_location_code)) := true;
         end if;
      end if;
      ----------------------
      -- pump_in_location --
      ----------------------
      if :new.pump_in_location_code is not null then
         if l_pumps.exists(:new.pump_in_location_code) then
            cwms_err.raise('ERROR', 'Pump is already used in a water supply contract');
         else
            l_pumps(to_char(:new.pump_in_location_code)) := true;
         end if;
      end if;
   end before each row;

end at_water_user_contract_t01;
/
