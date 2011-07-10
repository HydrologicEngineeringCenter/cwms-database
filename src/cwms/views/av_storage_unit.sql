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