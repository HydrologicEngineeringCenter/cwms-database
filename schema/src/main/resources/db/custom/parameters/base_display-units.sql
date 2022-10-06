declare
    l_office_code cwms_office.office_code%type := cwms_util.get_office_code('${CWMS_OFFICE_ID}');
begin
MERGE INTO at_display_units atdu
      USING (
        SELECT 
            l_office_code as office_code, 
            a.parameter_code as parameter_code, 
            'EN' as unit_system,
            b.display_unit_code_en as display_unit
        FROM 
            at_parameter a,
            cwms_base_parameter b
        WHERE 
            a.base_parameter_code = b.base_parameter_code
            AND 
            a.sub_parameter_id IS NULL
        ) basedu
    ON (atdu.db_office_code = basedu.office_code and atdu.unit_system=basedu.unit_system and atdu.parameter_code = basedu.parameter_code)
    WHEN MATCHED THEN 
        update set atdu.display_unit_code = basedu.display_unit
    WHEN NOT MATCHED THEN 
        insert(db_office_code,parameter_code,unit_system,display_unit_code)
        values(l_office_code,basedu.parameter_code,basedu.unit_system,basedu.display_unit);
        
MERGE INTO at_display_units atdu
      USING (
        SELECT 
            l_office_code as office_code, 
            a.parameter_code as parameter_code, 
            'SI' as unit_system,
            b.display_unit_code_si as display_unit
        FROM 
            at_parameter a,
            cwms_base_parameter b
        WHERE 
            a.base_parameter_code = b.base_parameter_code
            AND 
            a.sub_parameter_id IS NULL
        ) basedu
    ON (atdu.db_office_code = basedu.office_code and atdu.unit_system=basedu.unit_system and atdu.parameter_code = basedu.parameter_code)
    WHEN MATCHED THEN 
        update set atdu.display_unit_code = basedu.display_unit
    WHEN NOT MATCHED THEN 
        insert(db_office_code,parameter_code,unit_system,display_unit_code)
        values(l_office_code,basedu.parameter_code,basedu.unit_system,basedu.display_unit);        

end;
