insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DISPLAY_UNITS', null,
'
/**
 * Displays information on preferred units for specified parameters
 *
 * @since CWMS 2.1
 *
 * @field office_id    The office owning the preferences
 * @field parameter_id The parameter to specify preferred units for
 * @field unit_system  The unit system (EN or SI) that the preferred unit is specified for
 * @field unit_id      The preferred unit to use with the specified paramter and unit system
 */
');
CREATE OR REPLACE VIEW av_display_units
(
    office_id,
    parameter_id,
    unit_system,
    unit_id
)
AS
    SELECT    o.office_id,
                bp.base_parameter_id || SUBSTR ('-', 1, LENGTH (p.sub_parameter_id)) || p.sub_parameter_id AS parameter_id,
                d.unit_system, u.unit_id
      FROM    at_display_units d,
                cwms_office o,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_unit u
     WHERE         o.office_code = d.db_office_code
                AND p.parameter_code = d.parameter_code
                AND bp.base_parameter_code = p.base_parameter_code
                AND u.unit_code = display_unit_code
/
