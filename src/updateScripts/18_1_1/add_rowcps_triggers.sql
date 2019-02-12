declare
   l_table_names str_tab_t := str_tab_t(
      'at_document_type',
      'at_embank_protection_type',
      'at_embank_structure_type',
      'at_gate_ch_computation_code',
      'at_gate_release_reason_code',
      'at_operational_status_code',
      'at_physical_transfer_type',
      'at_project_purposes',
      'at_turbine_computation_code',
      'at_turbine_setting_reason',
      'at_ws_contract_type');
begin
   for i in 1..l_table_names.count loop
      execute immediate
'create or replace trigger '||l_table_names(i)||'_t1
   before insert or update or delete
   on '||l_table_names(i)||'
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         ''ERROR'',
         ''Cannot modify value owned by ''
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||'' from office ''
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end '||l_table_names(i)||'_t1;';
   end loop;
end;
/