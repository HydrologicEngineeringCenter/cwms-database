insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_SHEF_PE_CODES', null,
'
/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field shef_pe_code          [description needed]
 * @field base_parameter_id     [description needed]
 * @field sub_parameter_id      [description needed]
 * @field parameter_type_id     [description needed]
 * @field abstract_param_id     [description needed]
 * @field unit_id_en            [description needed]
 * @field unit_id_si            [description needed]
 * @field shef_duration_numeric [description needed]
 * @field shef_tse_code         [description needed]
 * @field description           [description needed]
 * @field db_office_id          [description needed]
 * @field abstract_param_code   [description needed]
 * @field unit_code_en          [description needed]
 * @field unit_code_si          [description needed]
 */
');
CREATE OR REPLACE FORCE VIEW av_shef_pe_codes
(
    shef_pe_code,
    base_parameter_id,
    sub_parameter_id,
    parameter_type_id,
    abstract_param_id,
    unit_id_en,
    unit_id_si,
    shef_duration_numeric,
    shef_tse_code,
    description,
    db_office_id,
    abstract_param_code,
    unit_code_en,
    unit_code_si
)
AS
    SELECT    a.shef_pe_code,
                CASE WHEN a.parameter_code = 0 THEN NULL ELSE c.base_parameter_id END base_parameter_id,
                CASE WHEN a.parameter_code = 0 THEN NULL ELSE b.sub_parameter_id END sub_parameter_id,
                CASE WHEN d.parameter_type_code = 0 THEN NULL ELSE parameter_type_id END parameter_type_id,
                i.abstract_param_id, e.unit_id unit_id_en, f.unit_id unit_id_si,
                g.shef_duration_numeric, a.shef_tse_code, a.description,
                'CWMS' db_office_id, i.abstract_param_code,
                e.unit_code unit_code_en, f.unit_code unit_code_si
      FROM    cwms_shef_pe_codes a,
                at_parameter b,
                cwms_base_parameter c,
                cwms_parameter_type d,
                cwms_unit e,
                cwms_unit f,
                cwms_shef_duration g,
                cwms_abstract_parameter i
     WHERE         a.parameter_code = b.parameter_code
                AND b.base_parameter_code = c.base_parameter_code
                AND a.parameter_type_code = d.parameter_type_code
                AND a.unit_code_en = e.unit_code(+)
                AND e.abstract_param_code = i.abstract_param_code
                AND a.unit_code_si = f.unit_code(+)
                AND a.shef_duration_code = g.shef_duration_code(+)
    UNION
    SELECT    a.shef_pe_code,
                CASE WHEN a.parameter_code = 0 THEN NULL ELSE c.base_parameter_id END base_parameter_id,
                CASE WHEN a.parameter_code = 0 THEN NULL ELSE b.sub_parameter_id END sub_parameter_id,
                CASE WHEN d.parameter_type_code = 0 THEN NULL ELSE parameter_type_id END parameter_type_id,
                i.abstract_param_id, e.unit_id unit_id_en, f.unit_id unit_id_si,
                g.shef_duration_numeric, a.shef_tse_code, a.description,
                h.office_id db_office_id, i.abstract_param_code,
                e.unit_code unit_code_en, f.unit_code unit_code_si
      FROM    at_shef_pe_codes a,
                at_parameter b,
                cwms_base_parameter c,
                cwms_parameter_type d,
                cwms_unit e,
                cwms_unit f,
                cwms_shef_duration g,
                cwms_office h,
                cwms_abstract_parameter i
     WHERE         a.parameter_code = b.parameter_code
                AND b.base_parameter_code = c.base_parameter_code
                AND a.parameter_type_code = d.parameter_type_code
                AND a.unit_code_en = e.unit_code(+)
                AND e.abstract_param_code = i.abstract_param_code
                AND a.unit_code_si = f.unit_code(+)
                AND a.shef_duration_code = g.shef_duration_code(+)
                AND a.db_office_code = h.office_code
    ORDER BY   shef_pe_code
/
