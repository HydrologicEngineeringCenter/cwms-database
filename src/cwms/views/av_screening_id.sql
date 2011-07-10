CREATE OR REPLACE VIEW av_screening_id
(
    screening_code,
    db_office_id,
    screening_id,
    screening_id_desc,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    duration_id
)
AS
    SELECT    atsi.screening_code, co.office_id db_office_id, atsi.screening_id,
                atsi.screening_id_desc, cbp.base_parameter_id,
                atp.sub_parameter_id,
                cbp.base_parameter_id || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id)) || atp.sub_parameter_id parameter_id,
                cpt.parameter_type_id, cd.duration_id
      FROM    at_screening_id atsi,
                cwms_office co,
                at_parameter atp,
                cwms_base_parameter cbp,
                cwms_parameter_type cpt,
                cwms_duration cd
     WHERE         co.office_code = atsi.db_office_code
                AND cbp.base_parameter_code = atsi.base_parameter_code
                AND atp.parameter_code = atsi.parameter_code
                AND atsi.parameter_type_code = cpt.parameter_type_code(+)
                AND atsi.duration_code = cd.duration_code(+)
/