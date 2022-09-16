declare
    p_abstract_parameter varchar2(32) := ?;
begin
  MERGE into cwms_20.cwms_abstract_parameter cap
        USING dual
        ON (cap.abstract_param_id = p_abstract_parameter)
        WHEN NOT MATCHED then
            insert( abstract_param_id )
            values( p_abstract_parameter )
;
end;
