CREATE OR REPLACE VIEW av_parameter
(
    db_office_id,
    db_office_code,
    parameter_code,
    base_parameter_code,
    base_parameter_id,
    sub_parameter_id,
    parameter_id
)
AS
    SELECT    a.office_id db_office_id, b.db_office_code, b.parameter_code,
                c.base_parameter_code, c.base_parameter_id, b.sub_parameter_id,
                c.base_parameter_id || SUBSTR ('-', 1, LENGTH (b.sub_parameter_id)) || b.sub_parameter_id parameter_id
      FROM    cwms_office a, at_parameter b, cwms_base_parameter c
     WHERE    b.db_office_code = a.db_host_office_code
                AND b.base_parameter_code = c.base_parameter_code
/