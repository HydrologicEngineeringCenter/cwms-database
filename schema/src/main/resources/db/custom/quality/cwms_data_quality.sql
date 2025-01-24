MERGE into cwms_20.cwms_data_quality dq
USING (select 
        ? as p_quality_code, -- 1
        ? as p_screened_id, -- 2
        ? as p_validity_id, -- 3
        ? as p_range_id, -- 4 
        ? as p_changed_id, -- 5
        ? as p_repl_cause_id, -- 6
        ? as p_repl_method_id, -- 7
        ? as p_test_failed_id, -- 8
        ? as p_protection_id -- 9
        from dual)
ON (dq.quality_code = p_quality_code)
WHEN MATCHED then
    update set
        dq.screened_id = p_screened_id,
        dq.validity_id = p_validity_id,
        dq.range_id = p_range_id,
        dq.changed_id = p_changed_id,
        dq.repl_cause_id = p_repl_cause_id,
        dq.repl_method_id = p_repl_method_id,
        dq.test_failed_id = p_test_failed_id,
        dq.protection_id = p_protection_id
WHEN NOT MATCHED then
    insert( quality_code,screened_id,validity_id,range_id,changed_id,repl_cause_id,repl_method_id,test_failed_id,protection_id)
    values( p_quality_code,
            p_screened_id,
            p_validity_id,
            p_range_id,
            p_changed_id,
            p_repl_cause_id,
            p_repl_method_id,
            p_test_failed_id,
            p_protection_id
        )
