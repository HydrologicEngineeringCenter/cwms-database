WITH ordered_wuca AS 
  (SELECT
    /*+ FIRST_ROWS(100) */
    wat_usr_contract_acct_code,
    water_user_contract_code,
    pump_location_code,
    physical_transfer_type_code,
    accounting_volume,
    transfer_start_datetime,
    accounting_remarks
  FROM at_wat_usr_contract_accounting
  WHERE water_user_contract_code = 623051
  AND transfer_start_datetime BETWEEN to_date('2010/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') AND to_date('2010/03/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss')
  ORDER BY cwms_util.to_millis(transfer_start_datetime) * -1),
  limited_wuca AS
  (SELECT wat_usr_contract_acct_code,
    water_user_contract_code,
    pump_location_code,
    physical_transfer_type_code,
    accounting_volume,
    transfer_start_datetime,
    accounting_remarks
  FROM ordered_wuca
  WHERE rownum <= 100
  )
SELECT limited_wuca.pump_location_code,
  to_char(limited_wuca.transfer_start_datetime,'yyyy/mm/dd-hh24:mi'),
  limited_wuca.accounting_volume,
  u.unit_id AS units_id,
  uc.factor,
  uc.offset,
  o.office_id AS transfer_type_office_id,
  ptt.phys_trans_type_display_value,
  ptt.physical_transfer_type_tooltip,
  ptt.physical_transfer_type_active,
  limited_wuca.accounting_remarks
FROM limited_wuca
INNER JOIN at_water_user_contract wuc
ON (limited_wuca.water_user_contract_code = wuc.water_user_contract_code)
INNER JOIN at_physical_transfer_type ptt
ON (limited_wuca.physical_transfer_type_code = ptt.physical_transfer_type_code)
inner join cwms_office o on ptt.db_office_code = o.office_code
INNER JOIN cwms_unit u
ON (wuc.storage_unit_code = u.unit_code)
INNER JOIN cwms_unit_conversion uc
ON uc.to_unit_code = wuc.storage_unit_code
INNER JOIN cwms_base_parameter bp
ON uc.from_unit_code     = bp.unit_code
AND bp.base_parameter_id = 'Stor'
