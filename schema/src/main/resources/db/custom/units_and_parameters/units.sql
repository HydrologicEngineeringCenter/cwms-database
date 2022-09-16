declare    
    p_unit_id varchar(16) := ?;
    p_abstract_param_id varchar(32) := ?;
    p_unit_system varchar(2) := ?;    
    p_long_name cwms_unit.long_name%type := ?;
    p_description cwms_unit.description%type := ?;
begin
MERGE into cwms_20.cwms_unit cu
        USING dual
        ON (cu.unit_id = p_unit_id)
        WHEN MATCHED then
            update set 
                cu.abstract_param_code = 
                    (select
                        abstract_param_code
                     from 
                        cwms_abstract_parameter 
                    where 
                        upper(abstract_param_id) = upper(p_abstract_param_id)
                    ),
                cu.unit_system = p_unit_system,
                cu.long_name = p_long_name,
                cu.description = p_description
        WHEN NOT MATCHED then
            insert( unit_id, abstract_param_code, unit_system, long_name, description )
            values( p_unit_id,
                    (select
                        abstract_param_code
                     from
                        cwms_abstract_parameter
                     where upper(abstract_param_id) = upper(p_abstract_param_id)
                    ),
                    p_unit_system,
                    p_long_name,
                    p_description
             )
;
end;
