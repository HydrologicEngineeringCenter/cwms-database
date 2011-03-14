set serveroutput on;
declare
l_project_loc_code number;
l_entity_name varchar2(100);
l_contract_name varchar2(100);
l_water_right varchar2(100);
l_contract_code number(10);
l_pump_loc_code number(10);
l_accounting_set_out wat_usr_contract_acct_tab_t;
p_accounting_tab wat_usr_contract_acct_tab_t;
l_factor number;
l_offset number;
l_time_zone varchar2(3);

l_project_office_id varchar2(100);
l_project_loc_id varchar2(100);

l_xfer_office_id varchar2(100);
l_xfer_display varchar2(100);
l_xfer_tooltip varchar2(100);
l_xfer_active  varchar2(100);

l_water_user_contract_ref water_user_contract_ref_t;
l_water_user water_user_obj_t;
l_proj_loc_ref location_ref_t;
l_pump_location_ref location_ref_t;
l_physical_transfer_type lookup_type_obj_t;
l_accounting_volume binary_double;
l_transfer_start_datetime date;
l_accounting_remarks varchar2(255 byte);

p_pump_time_window_tab loc_ref_time_window_tab_t;

l_start_time DATE;
l_end_time DATE;

l_count number;

BEGIN

    l_factor := 1.0;
    l_offset := 0;
    l_time_zone := 'UTC';
    
    --grab codes
    select wuc.water_user_contract_code, 
      wuc.contract_name, 
      wu.entity_name, 
      wu.water_right,
      wu.project_location_code, 
      o.office_id,
      bl.base_location_id,
      wuc.withdrawal_location_code
    into l_contract_code, 
      l_contract_name, 
      l_entity_name, 
      l_water_right,
      l_project_loc_code, 
      l_project_office_id,
      l_project_loc_id,
      l_pump_loc_code
    from at_water_user_contract wuc
      inner join at_water_user wu on (wuc.water_user_code = wu.water_user_code)
      inner join at_physical_location pl on (wu.project_location_code = pl.location_code)
      inner join at_base_location bl on (pl.base_location_code = bl.base_location_code)
      inner join cwms_office o on (bl.db_office_code = o.office_code)
    where rownum < 2;



    l_proj_loc_ref := new location_ref_t(l_project_loc_code);
    
    l_water_user := new water_user_obj_t(
        l_proj_loc_ref,
        l_entity_name,
        l_water_right 
      );
      
    l_water_user_contract_ref := new water_user_contract_ref_t(
      l_water_user,
      l_contract_name
    );

    l_pump_location_ref := new location_ref_t(l_pump_loc_code);
    
    select o.office_id,
      ptt.phys_trans_type_display_value,
      ptt.phys_trans_type_tooltip,
      ptt.phys_trans_type_active
    into   
      l_xfer_office_id,
      l_xfer_display,
      l_xfer_tooltip,
      l_xfer_active
    from at_physical_transfer_type ptt,
      cwms_office o    
    where ptt.db_office_code = o.office_code
    and rownum <2;
    
    l_physical_transfer_type := new lookup_type_obj_t(
      l_xfer_office_id,
      l_xfer_display,
      l_xfer_tooltip,
      l_xfer_active
    );
    
    l_accounting_volume := 3.0;
    l_transfer_start_datetime := to_date('2010/01/11-08:00:00', 'yyyy/mm/dd-hh24:mi:ss');
    l_accounting_remarks := null;
    
    p_accounting_tab := new wat_usr_contract_acct_tab_t();
--    p_accounting_tab.extend;
--    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
--        l_water_user_contract_ref,
--        l_pump_location_ref , 
--        l_physical_transfer_type,
--        l_accounting_volume,
--        l_transfer_start_datetime,                     
--        l_accounting_remarks
--    );
    p_accounting_tab.extend;
    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
        l_water_user_contract_ref,
        l_pump_location_ref , 
        l_physical_transfer_type,
        4.0,
        to_date('2010/01/11-08:15:00', 'yyyy/mm/dd-hh24:mi:ss'),                     
        l_accounting_remarks
    );
    p_accounting_tab.extend;
    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
        l_water_user_contract_ref,
        l_pump_location_ref , 
        l_physical_transfer_type,
        5.0,
        to_date('2010/01/11-08:30:00', 'yyyy/mm/dd-hh24:mi:ss'),                     
        l_accounting_remarks
    );
    dbms_output.put_line('record count: '||p_accounting_tab.count);
    p_accounting_tab.extend;
    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
        l_water_user_contract_ref,
        l_pump_location_ref , 
        l_physical_transfer_type,
        6.0,
        to_date('2010/01/11-08:45:00', 'yyyy/mm/dd-hh24:mi:ss'),                     
        l_accounting_remarks
    );
    dbms_output.put_line('record count: '||p_accounting_tab.count);
--    p_accounting_tab.extend;
--    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
--        l_water_user_contract_ref,
--        l_pump_location_ref , 
--        l_physical_transfer_type,
--        7.0,
--        to_date('2010/01/11-09:00:00', 'yyyy/mm/dd-hh24:mi:ss'),                     
--        l_accounting_remarks
--    );
--    dbms_output.put_line('record count: '||p_accounting_tab.count);

    p_pump_time_window_tab := new loc_ref_time_window_tab_t();
    p_pump_time_window_tab.extend;
    l_start_time := to_date('2010/01/11-08:15:00', 'yyyy/mm/dd-hh24:mi:ss');
    l_end_time := to_date('2010/01/11-08:45:00', 'yyyy/mm/dd-hh24:mi:ss');
    p_pump_time_window_tab(p_pump_time_window_tab.count) := new loc_ref_time_window_obj_t(
        l_pump_location_ref,
        l_start_time,
        l_end_time);
    
    cwms_water_supply.store_accounting_set(
        p_accounting_tab,
        l_water_user_contract_ref,
        p_pump_time_window_tab,
        l_time_zone,
        'm3',
        null,
        null);
    
    
    select count(*) into l_count from at_wat_usr_contract_accounting;
    dbms_output.put_line('row count: '||l_count);
    
    
    cwms_water_supply.retrieve_accounting_set(
      l_accounting_set_out,
      l_water_user_contract_ref,
      null,
      l_start_time,
      l_end_time,
      null,
      'T',
      'T',
      'T',
      10,
      null);
    
end;
