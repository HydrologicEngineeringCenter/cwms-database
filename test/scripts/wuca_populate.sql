DECLARE
l_acct_code NUMBER(10);
l_contract_code NUMBER(10);
l_pump_loc_code NUMBER(10);
l_xfer_type_code NUMBER(10);
l_volume BINARY_DOUBLE;
--l_start_date date;
l_date_time DATE;
l_index NUMBER;

CURSOR date_cur IS 
  WITH calendar AS (
      SELECT to_date('2000/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + (ROWNUM  - 1) * 1/96 c_date
      FROM dual
      CONNECT BY LEVEL <= (to_date('2011/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') - to_date('2000/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + 1) * 96
  )
  SELECT * FROM calendar;

BEGIN

SELECT water_user_contract_code, withdrawal_location_code 
  INTO l_contract_code,l_pump_loc_code 
  FROM at_water_user_contract WHERE ROWNUM < 2;
  
SELECT phys_trans_type_code 
  INTO l_xfer_type_code 
  FROM at_physical_transfer_type WHERE ROWNUM < 2;

l_index := 0;
OPEN date_cur;
loop
  fetch date_cur INTO l_date_time;
  exit WHEN date_cur%notfound;
  l_acct_code := cwms_seq.nextval;
  l_volume := l_index;
  l_index := l_index + 1;
  INSERT INTO at_wat_usr_contract_accounting VALUES (l_acct_code,l_contract_code, l_pump_loc_code, l_xfer_type_code, l_volume, l_date_time, NULL);
END loop;
CLOSE date_cur;
COMMIT;
END;
