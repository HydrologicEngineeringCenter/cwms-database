declare    
    p_quality_code     number := ?; -- 1
    p_screened_id    varchar2(2000) := ?; -- 2
    p_validity_id    varchar2(2000) := ?; -- 3
    p_range_id       varchar2(2000) := ?; -- 4 
    p_changed_id     varchar2(2000) := ?; -- 5
    p_repl_cause_id  varchar2(2000) := ?; -- 6
    p_repl_method_id varchar2(2000) := ?; -- 7
    p_test_failed_id varchar2(2000) := ?; -- 8
    p_protection_id  varchar2(2000) := ?; -- 9
begin
  
    MERGE into cwms_20.cwms_data_quality dq
        USING dual
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
    ;
end;