CREATE OR REPLACE VIEW at_tsv_view (ts_code, date_time, value, quality_code, data_entry_date)
	AS SELECT "TS_CODE" ,"DATE_TIME","VALUE","QUALITY_CODE","DATA_ENTRY_DATE" FROM at_tsv_2002
	UNION ALL
	SELECT    "TS_CODE","DATE_TIME","VALUE","QUALITY_CODE","DATA_ENTRY_DATE" FROM at_tsv_2003
	UNION ALL
	SELECT    "TS_CODE","DATE_TIME","VALUE","QUALITY_CODE","DATA_ENTRY_DATE" FROM at_tsv_2004
	UNION ALL
	SELECT    "TS_CODE","DATE_TIME","VALUE","QUALITY_CODE","DATA_ENTRY_DATE" FROM at_tsv_2005;

CREATE OR REPLACE VIEW pd_cwms_ts_id_view (office_id, cwms_ts_id, ts_code, 
	unit_id, interval_utc_offset)
	AS SELECT office_id,
		c.cwms_id||SUBSTR('-',1,LENGTH(s.subcwms_id))||s.subcwms_id||'.'
		||parameter_id||SUBSTR('-',1,LENGTH(s.subparameter_id))||s.subparameter_id||'.'
		||parameter_type_id||'.'
		||interval_id||'.'
		||duration_id||'.'
		||version cwms_ts_id,
       ts_code,
       unit_id,
	   interval_utc_offset
  FROM at_cwms_name c,
       cwms_office o,
       at_physical_location l,
       at_cwms_ts_spec s,
       cwms_parameter p,
       cwms_parameter_type t,
       cwms_interval i,
       cwms_duration d,
       cwms_unit u
  WHERE c.office_code = o.office_code
    AND c.cwms_code = l.cwms_code
    AND l.location_code = s.location_code
    AND s.parameter_code = p.parameter_code
    AND s.parameter_type_code = t.parameter_type_code
    AND s.interval_code = i.interval_code
    AND s.duration_code = d.duration_code
    AND u.unit_code = p.unit_code;
/*
DROP MATERIALIZED VIEW pd_cwms_ts_id_mview;
CREATE MATERIALIZED VIEW pd_cwms_ts_id_mview
	REFRESH COMPLETE ON DEMAND
	ENABLE QUERY REWRITE
	AS SELECT office_id, cwms_ts_id, ts_code, unit_id, interval_utc_offset 
	FROM pd_cwms_ts_id_view;
*/
CREATE OR REPLACE  VIEW pd_cwms_ts_id_mview
	AS SELECT office_id, cwms_ts_id, ts_code, unit_id, interval_utc_offset 
	FROM pd_cwms_ts_id_view;

	CREATE OR REPLACE VIEW AT_TSV_DQU_VIEW ( TS_CODE, 
	DATA_ENTRY_DATE, DATE_TIME, VALUE, OFFICE_ID, 
	UNIT_ID, CWMS_TS_ID, CHANGED_ID, PROTECTION_ID, 
	RANGE_ID, REPL_CAUSE_ID, REPL_METHOD_ID, TEST_FAILED_ID, 
	SCREENED_ID, VALIDITY_ID, QUALITY_CODE ) AS select tsv.ts_code,
	tsv.data_entry_date,
	tsv.date_time,
	tsv.value*c.FACTOR+c.OFFSET value,
	ts.office_id,
	cu2.unit_id,
	ts.cwms_ts_id,
	dq.changed_id,
	dq.protection_id,
	dq.range_id,
	dq.repl_cause_id,
	dq.repl_method_id,
	dq.test_failed_id,
	dq.screened_id,
	dq.validity_id,
	tsv.quality_code
	from at_tsv_view tsv,
	pd_cwms_ts_id_mview ts,
	cwms_data_quality dq,
	/*
	cwms_data_q_changed dqc,
	cwms_data_q_protection dqp,
	cwms_data_q_range dqr,
	cwms_data_q_repl_cause dqrc,
	cwms_data_q_repl_method dqrm,
	cwms_data_q_test_failed dqt,
	cwms_data_q_screened dqs,
	cwms_data_q_validity dv,
	*/
	cwms_unit cu,
	cwms_unit_conversion c,
	cwms_unit cu2
	where
	--joins
	tsv.ts_code = ts.ts_code
	and tsv.quality_code = dq.quality_code
	/*
	and dq.changed_code = dqc.changed_code
	and dq.protection_code = dqp.protection_code
	and dq.range_code = dqr.range_code
	and dq.repl_cause_code = dqrc.repl_cause_code
	and dq.repl_method_code = dqrm.repl_method_code
	and dq.test_failed_code = dqt.test_failed_code
	and dq.screened_code = dqs.screened_code
	and dq.validity_code = dv.validity_code
	*/
	and ts.unit_id = cu.unit_id
	and cu.unit_code = c.from_unit_code
	and c.to_unit_code = cu2.unit_code;



