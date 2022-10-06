declare
	p_parameter_code at_parameter.parameter_code%type := ?;
	p_base_parm_id cwms_base_parameter.base_parameter_id%type := ?;
	p_sub_parm_id at_parameter.sub_parameter_id%type := ?;
	p_sub_parm_desc at_parameter.sub_parameter_desc%type := ?;

	l_base_param_code at_parameter.base_parameter_code%type;
	l_office_code cwms_office.office_code%type := cwms_util.get_office_code('CWMS');
	
--           --  DEFAULT Sub_Parameters -------------------------------    -- Display Units --
--    Param  Base        Sub
--    Code   Param       Param          Sub-Parameter Descripiton           SI         Non-SI
--    ----- ----------- -------------- ---------------------------------- ---------- ---------
begin
  select base_parameter_code into l_base_param_code from cwms_base_parameter where base_parameter_id = p_base_parm_id;  

  MERGE into cwms_20.at_parameter atp
        USING dual
        ON (atp.parameter_code = p_parameter_code and atp.db_office_code = l_office_code)
		WHEN MATCHED then
			update set
				base_parameter_code = l_base_param_code,
				sub_parameter_id  = p_sub_parm_id,
				sub_parameter_desc = p_sub_parm_desc
        WHEN NOT MATCHED then
            insert(PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC)
            values(p_parameter_code,l_base_param_code,p_sub_parm_id,l_office_code,p_sub_parm_desc);
end;
