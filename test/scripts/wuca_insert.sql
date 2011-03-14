set serveroutput on;
declare
l_project_loc_code number;
l_entity_name varchar2(100);
l_contract_name varchar2(100);
l_water_right varchar2(100);
l_contract_code number(10);
l_pump_loc_code number(10);
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
    
    l_accounting_volume := 1.0;
    l_transfer_start_datetime := to_date('2010/01/11-00:00:00', 'yyyy/mm/dd-hh24:mi:ss');
    l_accounting_remarks := null;
    
    p_accounting_tab := new wat_usr_contract_acct_tab_t();
    p_accounting_tab.extend;
    p_accounting_tab(p_accounting_tab.count) := new wat_usr_contract_acct_obj_t(
        l_water_user_contract_ref,
        l_pump_location_ref , 
        l_physical_transfer_type,
        l_accounting_volume,
        l_transfer_start_datetime,                     
        l_accounting_remarks
    );
    dbms_output.put_line('record count: '||p_accounting_tab.count);


    


--    dbms_output.put_line('code: '||l_project_loc_code 
--            ||' loc ref: '||l_proj_loc_ref.get_location_code('F') 
--            ||' contract: '||l_water_user_contract_ref.water_user.project_location_ref.get_location_code('F') 
--            ||' tab: '||p_accounting_tab(1).water_user_contract_ref.water_user.project_location_ref.get_location_code('F'));
--
--    for rec in ( 
--        select 
--               (  acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id || ';' || 
--                  acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id || '-' || 
--                  acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
--               ) proj_code1,
--               cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
--                  acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
--                  || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
--                  || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
--               ) proj_code2,
--               acct_tab.water_user_contract_ref.water_user.project_location_ref.get_location_code('F') proj_code3,
--               acct_tab.project_location_ref.get_location_code('F') proj_code4,
--               acct_tab.pump_location_ref.get_location_code('F') pump_code
--        from table (cast (p_accounting_tab as wat_usr_contract_acct_tab_t)) acct_tab
--    )
--    loop
--        dbms_output.put_line(
--          rec.proj_code1|| ',' || 
--          rec.proj_code2|| ',' || 
--          rec.proj_code3|| ',' || 
--          rec.proj_code4|| ',' || 
--          rec.pump_code);        
--    end loop;            
    
    
    -- insert new data
    INSERT INTO at_wat_usr_contract_accounting (
        wat_usr_contract_acct_code,
        water_user_contract_code,
        pump_location_code,
        phys_trans_type_code,
        accounting_volume,
        transfer_start_datetime,
        accounting_remarks )

        select cwms_seq.nextval pk_code,
            l_contract_code contract_code,
            acct_tab.pump_location_ref.get_location_code('F') pump_code,
            ptt.phys_trans_type_code xfer_code,
            acct_tab.accounting_volume * l_factor + l_offset volume,
            cwms_util.change_timezone(
                  acct_tab.transfer_start_datetime, 
                  l_time_zone, 
                  'UTC'
              ) xfer_date,
            acct_tab.accounting_remarks remarks
        from table (cast (p_accounting_tab as wat_usr_contract_acct_tab_t)) acct_tab,
            at_physical_transfer_type ptt,
            cwms_office o,
            at_water_user_contract wuc,
            at_water_user wu
        where wuc.water_user_code = wu.water_user_code
        and wuc.water_user_contract_code = l_contract_code
        and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
              acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
              || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
              || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
            ) = l_project_loc_code
        and upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name)
        AND upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name)
        and acct_tab.physical_transfer_type.office_id = o.office_id
        and acct_tab.physical_transfer_type.display_value = ptt.phys_trans_type_display_value
        and ptt.db_office_code = o.office_code;

    
--    for rec in (
--        select cwms_seq.nextval pk_code,
--            l_contract_code contract_code,
--            acct_tab.pump_location_ref.get_location_code('F') pump_code,
--            ptt.phys_trans_type_code xfer_code,
--            acct_tab.accounting_volume * l_factor + l_offset volume,
--            cwms_util.change_timezone(
--                  acct_tab.transfer_start_datetime, 
--                  l_time_zone, 
--                  'UTC'
--              ) xfer_date,
--            acct_tab.accounting_remarks remarks
--        from table (cast (p_accounting_tab as wat_usr_contract_acct_tab_t)) acct_tab,
--            at_physical_transfer_type ptt,
--            cwms_office o,
--            at_water_user_contract wuc,
--            at_water_user wu
--        where wuc.water_user_code = wu.water_user_code
--        and wuc.water_user_contract_code = l_contract_code
--        and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
--              acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
--              || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
--              || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
--            ) = l_project_loc_code
--        and upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name)
--        AND upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name)
--        and acct_tab.physical_transfer_type.office_id = o.office_id
--        and acct_tab.physical_transfer_type.display_value = ptt.phys_trans_type_display_value
--        and ptt.db_office_code = o.office_code 
--        )
--    loop
--            dbms_output.put_line(rec.pk_code||','
--                ||rec.contract_code||','
--                ||rec.pump_code||','
--                ||rec.xfer_code||','
--                ||rec.volume||','
--                ||rec.xfer_date||','
--                ||rec.remarks
--        );
--      END loop;           
    
end;
