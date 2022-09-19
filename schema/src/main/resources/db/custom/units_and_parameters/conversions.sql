/*CREATE TABLE CWMS_UNIT_CONVERSION
    (
      FROM_UNIT_ID        VARCHAR2(16 BYTE)       NOT NULL,
      TO_UNIT_ID          VARCHAR2(16 BYTE)       NOT NULL,
      ABSTRACT_PARAM_CODE NUMBER(14)              NOT NULL,
      FROM_UNIT_CODE      NUMBER(14)              NOT NULL,
      TO_UNIT_CODE        NUMBER(14)              NOT NULL,
      FACTOR              BINARY_DOUBLE,
      OFFSET              BINARY_DOUBLE,
      FUNCTION            VARCHAR2(64),*/
declare
    p_from_id varchar(16) := ?;
    p_to_id varchar(16) := ?;
    p_abstract_param_id cwms_abstract_parameter.abstract_param_id%type := ?;    
    p_factor binary_double := ?;
    p_offset binary_double := ?;
    p_function varchar2(64) := ?;
begin
MERGE into cwms_20.cwms_unit_conversion cuc
        USING dual
        ON (cuc.from_unit_id = p_from_id and cuc.to_unit_id = p_to_id)
        WHEN MATCHED then
            update set
                cuc.abstract_param_code = 
                    (select 
                        abstract_param_code 
                     from 
                        cwms_abstract_parameter 
                    where 
                        abstract_param_id = p_abstract_param_id
                    ),
                    cuc.factor = p_factor,
                    cuc.offset = p_offset,
                    cuc.function = p_function
        WHEN NOT MATCHED then
            insert(from_unit_code,to_unit_code,from_unit_id,to_unit_id,abstract_param_code,factor,offset,function)
            values(
                (select unit_code from cwms_unit where unit_id=p_from_id),
                (select unit_code from cwms_unit where unit_id=p_to_id),
                p_from_id,
                p_to_id,
                (select abstract_param_code from cwms_abstract_parameter where abstract_param_id = p_abstract_param_id),
                p_factor,
                p_offset,
                p_function                
            )
;
end;
