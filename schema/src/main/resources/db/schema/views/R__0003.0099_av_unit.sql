/**
 * Displays information about units
 *
 * @since CWMS 2.0
 *
 * @field unit_system         The unit system (EN or SI) that the unit is associated with
 * @field unit_id             The unit identifier
 * @field abstract_param_id   The abstract parameter associated with the unit
 * @field long_name           A longer name for the unit
 * @field description         Describes the unit
 * @field db_office_id        Office that owns the unit
 * @field unit_code           Unique numeric value that identifies the unit
 * @field abstract_param_code Unique numeric value that identifies the abstract parameter associated with the unit
 * @field db_office_code      Unique numeric value that identifies the office that owns the unit
 */
CREATE OR REPLACE FORCE VIEW av_unit
(
    unit_system,
    unit_id,
    abstract_param_id,
    long_name,
    description,
    db_office_id,
    unit_code,
    abstract_param_code,
    db_office_code
)
AS
    SELECT    a.unit_system, a.unit_id, b.abstract_param_id, a.long_name,
                a.description, 'CWMS' db_office_id, a.unit_code,
                a.abstract_param_code, 53 db_office_code
      FROM    cwms_unit a, cwms_abstract_parameter b
     WHERE    b.abstract_param_code = a.abstract_param_code
    UNION
    SELECT    b.unit_system, a.alias_id unit_id, c.abstract_param_id,
                b.long_name, b.description, d.office_id db_office_id, a.unit_code,
                b.abstract_param_code, a.db_office_code
      FROM    at_unit_alias a,
                cwms_unit b,
                cwms_abstract_parameter c,
                cwms_office d
     WHERE         b.unit_code = a.unit_code
                AND b.abstract_param_code = c.abstract_param_code
                AND a.db_office_code = d.office_code
/