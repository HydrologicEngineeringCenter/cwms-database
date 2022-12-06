declare
	p_base_parm_code cwms_base_parameter.base_parameter_code%type := ?;
    p_abstract_parameter cwms_abstract_parameter.abstract_param_id%type := ?;
	p_id cwms_base_parameter.base_parameter_id%type := ?;
	p_long_name cwms_base_parameter.long_name%type := ?;
	p_store_unit_id cwms_unit.unit_id%type := ?;
	p_display_si_id cwms_unit.unit_id%type := ?;
	p_display_non_si_id cwms_unit.unit_id%type := ?;
	p_description cwms_base_parameter.description%type := ?;

	l_abstract_param_code cwms_abstract_parameter.abstract_param_id%type;
	l_store_unit_code cwms_unit.unit_code%type := cwms_util.get_unit_code(p_store_unit_id);
	l_display_si_code cwms_unit.unit_code%type := cwms_util.get_unit_code(p_display_si_id);
	l_display_non_si_code cwms_unit.unit_code%type := cwms_util.get_unit_code(p_display_non_si_id);
	l_office_code cwms_office.office_code%type := cwms_util.get_office_code('CWMS');
--                                                                                     db        -----    Default  ------
--                                                                                    store      ------Display Units-----
--   CODE   ABSTRACT PARAMETER                  ID             NAME                  UNIT ID      SI       Non-SI         DESCRIPTION
begin
  select abstract_param_code into l_abstract_param_code from cwms_abstract_parameter where abstract_param_id = p_abstract_parameter;

  MERGE into cwms_20.cwms_base_parameter cbp
        USING dual
        ON (cbp.base_parameter_code = p_base_parm_code)
		WHEN MATCHED then
			update set
				cbp.base_parameter_id = p_id,
				cbp.abstract_param_code = l_abstract_param_code,
				cbp.unit_code = l_store_unit_code,
				cbp.display_unit_code_si = l_display_si_code,
				cbp.display_unit_code_en = l_display_non_si_code,
				cbp.long_name = p_long_name,
				cbp.description = p_description
        WHEN NOT MATCHED then
            insert(base_parameter_code,base_parameter_id,abstract_param_code,
				   unit_code,display_unit_code_si,display_unit_code_en,
				   long_name,description)
            values(p_base_parm_code,p_id,l_abstract_param_code,
				   l_store_unit_code,l_display_si_code,l_display_non_si_code,
				   p_long_name,p_description
			)
;

-- Each base parameter also needs to exist in the at_parameter table
	MERGE into cwms_20.at_parameter atp
		USING dual				
		ON (	atp.parameter_code = p_base_parm_code
			and	atp.base_parameter_code = p_base_parm_code 
			and atp.sub_parameter_id is NULL 
			and db_office_code = l_office_code)
		WHEN MATCHED then
			update set atp.sub_parameter_desc = p_description
		WHEN NOT MATCHED then
			insert(PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC)
            values(p_base_parm_code,p_base_parm_code,NULL,l_office_code,p_long_name);
		

/*
BASE_PARAMETER_CODE	NUMBER(14,0)
BASE_PARAMETER_ID	VARCHAR2(16 BYTE)
ABSTRACT_PARAM_CODE	NUMBER(14,0)
UNIT_CODE	NUMBER(14,0)
DISPLAY_UNIT_CODE_SI	NUMBER(14,0)
DISPLAY_UNIT_CODE_EN	NUMBER(14,0)
LONG_NAME	VARCHAR2(80 BYTE)
DESCRIPTION	VARCHAR2(160 BYTE)
*/
end;
