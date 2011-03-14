SET serveroutput ON
DECLARE 
    -- the contract ref for the incoming accountings.
    p_contract_ref water_user_contract_ref_t;
    l_contract_name at_water_user_contract.contract_name%TYPE;
    l_entity_name at_water_user.entity_name%TYPE;
    l_project_loc_code NUMBER(10);
    l_contract_code NUMBER(10);
    
    l_factor         BINARY_DOUBLE;
    l_offset         binary_double;
    p_volume_unit_id varchar2(16);
    
BEGIN


l_contract_name := 'WU CONTRACT 1'; --p_contract_ref.contract_name;
l_entity_name := 'KEYS WU 1'; --p_contract_ref.water_user.entity_name;
l_project_loc_code := 32051; --p_contract_ref.water_user.project_location_ref.get_location_code('F');

SELECT wuc.water_user_contract_code
INTO l_contract_code 
FROM at_water_user_contract wuc
INNER JOIN at_water_user wu ON (wuc.water_user_code = wu.water_user_code)
WHERE upper(wuc.contract_name) = upper(l_contract_name)
AND upper(wu.entity_name) = upper(l_entity_name)
AND wu.project_location_code = l_project_loc_code;

dbms_output.put_line('wuc code: '|| l_contract_code);

p_volume_unit_id := null;

       ----------------------------------
       -- get the unit conversion info --
       ----------------------------------
    SELECT uc.factor,
          uc.offset
     INTO l_factor,
          l_offset
     from cwms_base_parameter bp,
          cwms_unit_conversion uc,
          cwms_unit u
    WHERE bp.base_parameter_id = 'Stor'
      and uc.to_unit_code = bp.unit_code
      and uc.from_unit_code = u.unit_code
      and u.unit_id = nvl(p_volume_unit_id,'m3');
      
dbms_output.put_line('unit conv: '|| l_factor ||', '||l_offset);

END;
