insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STORAGE_UNIT', null,
'
/**
 * Displays storage units for parameters
 *
 * @since CWMS 2.1
 *
 * @field base_parameter_id The base parameter identifier
 * @field sub_parameter_id  The sub-parameter identifier, if any
 * @field unit_id           The database storage unit
 */
');
CREATE OR REPLACE FORCE VIEW av_storage_unit
(
    base_parameter_id,
    sub_parameter_id,
    unit_id
)
AS
    SELECT    base_parameter_id, sub_parameter_id, unit_id
      FROM    at_parameter ap, cwms_base_parameter bp, cwms_unit u
     WHERE    ap.base_parameter_code = bp.base_parameter_code
                AND bp.unit_code = u.unit_code
/