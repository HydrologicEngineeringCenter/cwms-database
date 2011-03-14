set serveroutput on
DECLARE
    --the pumps that are having accountings stored.
    p_pump_loc_ref_tab loc_ref_time_window_tab_t;
    -- the time zone of all of the incoming data.
    l_time_zone VARCHAR2(3) := 'UTC';
    
    l_contract_code NUMBER(10);
    l_start DATE;
    l_end DATE;
    l_pump_loc_code NUMBER(10);
    l_wuca_acct_code NUMBER(10);

    CURSOR pump_tw_cur IS 
      SELECT loc_tw_tab.location_ref.get_location_code('F') loc_code, 
        loc_tw_tab.start_date start_date, 
        loc_tw_tab.end_date end_date
      FROM TABLE (CAST (p_pump_loc_ref_tab AS loc_ref_time_window_tab_t)) loc_tw_tab;
      
    CURSOR wuca_acct_code_cur IS
        SELECT wat_usr_contract_acct_code
        FROM at_wat_usr_contract_accounting 
        WHERE wat_usr_contract_acct_code IN (
            SELECT wuca.wat_usr_contract_acct_code acct_code
            FROM at_wat_usr_contract_accounting wuca
            INNER JOIN (
                SELECT loc_tw_tab.location_ref.get_location_code('F') loc_code, 
                    -- convert to utc
                    cwms_util.change_timezone(
                      loc_tw_tab.start_date, 
                      l_time_zone, 
                      'UTC'
                    )  start_date,
                    cwms_util.change_timezone(
                      loc_tw_tab.end_date , 
                      l_time_zone, 
                      'UTC'
                    ) end_date
                FROM TABLE (CAST (p_pump_loc_ref_tab AS loc_ref_time_window_tab_t)) loc_tw_tab
            ) loc_tw ON (
                wuca.pump_location_code = loc_tw.loc_code 
                -- wuca times are in utc.
                AND wuca.transfer_start_datetime BETWEEN loc_tw.start_date AND loc_tw.end_date
            )
            WHERE wuca.water_user_contract_code = l_contract_code
        );

      
    
BEGIN

--p_pump_loc_ref_tab := location_ref_tab_t();
--p_pump_loc_ref_tab.EXTEND;
--P01Jan11 080000-WITHDRAW 1 

p_pump_loc_ref_tab := loc_ref_time_window_tab_t();

p_pump_loc_ref_tab.EXTEND;
p_pump_loc_ref_tab(p_pump_loc_ref_tab.count) := loc_ref_time_window_obj_t(
  NEW location_ref_t('P01Jan11 080000-WITHDRAW 1','SWT'),
  to_date('2010/02/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'),
  to_date('2010/02/12-08:00:00', 'yyyy/mm/dd-hh24:mi:ss')
);

p_pump_loc_ref_tab.EXTEND;
p_pump_loc_ref_tab(p_pump_loc_ref_tab.count) := loc_ref_time_window_obj_t(
  NEW location_ref_t('P01Jan11 080000-WITHDRAW 1','SWT'),
  to_date('2010/02/14-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'),
  to_date('2010/02/16-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'));

p_pump_loc_ref_tab.EXTEND;
p_pump_loc_ref_tab(p_pump_loc_ref_tab.count) := loc_ref_time_window_obj_t(
  NEW location_ref_t('P01Jan11 080000-WITHDRAW 1','SWT'),
  to_date('2010/02/18-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'),
  to_date('2010/02/20-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'));

p_pump_loc_ref_tab.EXTEND;
p_pump_loc_ref_tab(p_pump_loc_ref_tab.count) := loc_ref_time_window_obj_t(
  NEW location_ref_t('P01Jan11 080000-WITHDRAW 1','SWT'),
  to_date('2010/02/22-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'),
  to_date('2010/02/24-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'));

p_pump_loc_ref_tab.EXTEND;
p_pump_loc_ref_tab(p_pump_loc_ref_tab.count) := loc_ref_time_window_obj_t(
  NEW location_ref_t('P01Jan11 080000-WITHDRAW 1','SWT'),
  to_date('2010/02/26-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'),
  to_date('2010/02/28-08:00:00', 'yyyy/mm/dd-hh24:mi:ss'));

dbms_output.put_line('rowcount: '||p_pump_loc_ref_tab.count);


open pump_tw_cur;
loop
  fetch pump_tw_cur into l_pump_loc_code,l_start,l_end;
  exit WHEN pump_tw_cur%notfound;
  dbms_output.put_line('loc code: '||l_pump_loc_code||' start: '||l_start || ' end: '||l_end);
END loop;
CLOSE pump_tw_cur;

l_contract_code := 35051;

DELETE 
FROM at_wat_usr_contract_accounting 
WHERE wat_usr_contract_acct_code IN (
    SELECT wuca.wat_usr_contract_acct_code acct_code
    FROM at_wat_usr_contract_accounting wuca
    INNER JOIN (
        SELECT loc_tw_tab.location_ref.get_location_code('F') loc_code, 
                -- convert to utc
                cwms_util.change_timezone(
                  loc_tw_tab.start_date, 
                  l_time_zone, 
                  'UTC'
                )  start_date,
                cwms_util.change_timezone(
                  loc_tw_tab.end_date , 
                  l_time_zone, 
                  'UTC'
                ) end_date
        FROM TABLE (CAST (p_pump_loc_ref_tab AS loc_ref_time_window_tab_t)) loc_tw_tab
    ) loc_tw ON (
        wuca.pump_location_code = loc_tw.loc_code 
        -- wuca times are in utc.
        AND wuca.transfer_start_datetime BETWEEN loc_tw.start_date AND loc_tw.end_date
    )
    WHERE wuca.water_user_contract_code = l_contract_code
);


open wuca_acct_code_cur;
loop
  fetch wuca_acct_code_cur into l_wuca_acct_code;
  exit WHEN wuca_acct_code_cur%notfound;
  dbms_output.put_line('acct code: '||l_wuca_acct_code);
END loop;
CLOSE wuca_acct_code_cur;
      
END;


