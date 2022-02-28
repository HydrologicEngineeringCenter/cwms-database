create or replace trigger at_document_type_t1
   before insert or update or delete
   on at_document_type
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_document_type_t1;
/
create or replace trigger at_embank_protection_type_t1
   before insert or update or delete
   on at_embank_protection_type
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_embank_protection_type_t1;
/
create or replace trigger at_embank_structure_type_t1
   before insert or update or delete
   on at_embank_structure_type
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_embank_structure_type_t1;
/
create or replace trigger at_gate_ch_computation_code_t1
   before insert or update or delete
   on at_gate_ch_computation_code
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_gate_ch_computation_code_t1;
/
create or replace trigger at_gate_release_reason_code_t1
   before insert or update or delete
   on at_gate_release_reason_code
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_gate_release_reason_code_t1;
/
create or replace trigger at_operational_status_code_t1
   before insert or update or delete
   on at_operational_status_code
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_operational_status_code_t1;
/
create or replace trigger at_physical_transfer_type_t1
   before insert or update or delete
   on at_physical_transfer_type
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_physical_transfer_type_t1;
/
create or replace trigger at_project_purposes_t1
   before insert or update or delete
   on at_project_purposes
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_project_purposes_t1;
/
create or replace trigger at_turbine_computation_code_t1
   before insert or update or delete
   on at_turbine_computation_code
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_turbine_computation_code_t1;
/
create or replace trigger at_turbine_setting_reason_t1
   before insert or update or delete
   on at_turbine_setting_reason
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_turbine_setting_reason_t1;
/
create or replace trigger at_ws_contract_type_t1
   before insert or update or delete
   on at_ws_contract_type
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_ws_contract_type_t1;
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