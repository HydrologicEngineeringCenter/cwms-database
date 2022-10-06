merge into at_parameter atp
        using (select
                    base_parameter_code, 
                    (select ofc.office_code
                    from cwms_office ofc
                    where office_id = 'CWMS') as office_code,
                    long_name
                from cwms_base_parameter) cbp
        on (atp.base_parameter_code = cbp.base_parameter_code and atp.db_office_code = cbp.office_code)
        when matched then update
            set atp.sub_parameter_desc = cbp.long_name
        when not matched then 
            insert (PARAMETER_CODE,DB_OFFICE_CODE,BASE_PARAMETER_CODE,SUB_PARAMETER_ID,SUB_PARAMETER_DESC)
            values (cbp.base_parameter_code,cbp.office_code,cbp.base_parameter_code,NULL,cbp.long_name)

;
