set serveroutput on;
DECLARE
  l_accounting_set    wat_usr_contract_acct_tab_t;
  l_store_rule        VARCHAR2(50);
  l_start_time        DATE;
  l_end_time          DATE;
  l_time_zone         VARCHAR2(100);
  l_start_inclusive   VARCHAR2(1);
  l_end_inclusive     VARCHAR2(1);
  l_override_prot     VARCHAR2(1);
  l_base_location_id  VARCHAR2(100);

l_contract_ref water_user_contract_ref_t;
l_pump_location_ref location_ref_t;

  l_physical_transfer_type lookup_type_obj_t;
  l_accounting_volume BINARY_DOUBLE;
  l_units_id VARCHAR2(16);
  l_transfer_start_datetime DATE;
  l_accounting_remarks VARCHAR2(255 BYTE);
  
  l_index NUMBER;
  l_date_time DATE;
  
cursor date_cur is 
  with calendar as (
      SELECT to_date('2010/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + (ROWNUM  - 1) * 1/96 c_date
      FROM dual
      connect by level <= (to_date('2010/02/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') - to_date('2010/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + 1) * 96
  )
  SELECT * FROM calendar;

BEGIN



l_store_rule := cwms_util.delete_insert;
l_start_time := NULL; --to_date('2010/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss');
l_end_time := null; -- to_date('2010/02/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss');
l_time_zone := 'UTC';
l_start_inclusive := 'T';
l_end_inclusive := 'T';
l_override_prot := 'T';
l_units_id := 'm3';


SELECT base_location_id 
INTO l_base_location_id 
FROM at_water_user, at_physical_location, at_base_location
WHERE 
  at_water_user.project_location_code = at_physical_location.location_code
  and at_base_location.base_location_code = at_physical_location.base_location_code;

l_contract_ref := water_user_contract_ref_t(
    water_user_obj_t(
      NEW location_ref_t(l_base_location_id,'SWT'),
      'KEYS WU 1',
      'WU RIGHT 1'
    ),
    'WU CONTRACT 1'
);

l_pump_location_ref := location_ref_t(l_base_location_id||'-WITHDRAW 1','SWT');
l_physical_transfer_type := lookup_type_obj_t(
    'SWT',
    'XFER TYPE 1',
    'XFER TYPE 1 DESC',
    'T'
);

l_accounting_set := wat_usr_contract_acct_tab_t();
open date_cur;
loop
  fetch date_cur into l_date_time;
  exit WHEN date_cur%notfound;
  
    l_accounting_volume := l_index;
    l_index := l_index + 1;
    
    l_accounting_set.EXTEND;
    l_accounting_set(1) := wat_usr_contract_acct_obj_t(
        l_contract_ref,
        l_pump_location_ref,
        l_physical_transfer_type,
        l_accounting_volume,
        l_units_id,
        l_date_time,
        null
    );
end loop;
CLOSE date_cur;

--cwms_water_supply.store_accounting_set(
--  l_accounting_set,
--  l_store_rule,
--  l_start_time,
--  l_end_time,
--  l_time_zone,
--  l_start_inclusive,
--  l_end_inclusive,
--  l_override_prot
--  );

--       SELECT water_user_code
--         INTO l_water_usr_code
--         FROM at_water_user
--        WHERE project_location_code = l_ref.water_user.project_location_ref.get_location_code
--          AND upper(entity_name) = upper(l_ref.water_user.entity_name);
--      
--       ---------------------------
--       -- get the contract code --
--       ---------------------------
--       SELECT water_user_contract_code
--         INTO l_contract_code
--         FROM at_water_user_contract
--        WHERE water_user_code = l_water_usr_code 
--          AND upper(contract_name) = upper(l_ref.contract_name);
--
--DELETE FROM at_wat_usr_contract_accounting 
--WHERE water_user_contract_code = 0
--AND pump_location_code = 0
--AND transfer_start_datetime between 



  
COMMIT;



--PROCEDURE store_accounting_set(
--    -- the set of water user contract accountings to store to the database.
--    p_accounting_set IN wat_usr_contract_acct_tab_t,
--    -- a flag that will cause the procedure to fail if the objects already exist
--    -- p_fail_if_exists in varchar2 default 'T' 
--
--		-- store rule, only delete insert initially supported.
--    p_store_rule		IN VARCHAR2 DEFAULT NULL,
--    -- start time of data to delete.
--    p_start_time	  IN		DATE DEFAULT NULL,
--    --end time of data to delete.
--    p_end_time		  IN		DATE DEFAULT NULL,
--    -- the time zone of the incoming data.
--    p_time_zone IN VARCHAR2 DEFAULT NULL,    
--    -- if the start time is inclusive.
--    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
--    -- if the end time is inclusive
--    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
--    -- if protection is to be ignored, not initially supported.
--		p_override_prot	IN VARCHAR2 DEFAULT 'F'
--    )   


  dbms_output.put_line('count: '|| l_index || ' records.');
  dbms_output.put_line('ready to store '|| l_accounting_set.count || ' records.');


end;
