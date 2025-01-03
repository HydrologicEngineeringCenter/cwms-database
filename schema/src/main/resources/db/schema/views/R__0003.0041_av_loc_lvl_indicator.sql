/**
 * Displays information about location level indicators with each indicator condition in its own row
 *
 * @since CWMS 2.1
 *
 * @field office_id                 Office that owns the indicator
 * @field level_indicator_id        Identifies the indicator
 * @field reference_level_id        Identifies the referenced location level, if any
 * @field attribute_id              Identifies the location level attribute, if any
 * @field unit_system               Species the unit system (EN or SI) used for the expressions
 * @field attribute_value           The value of the attribute, if any
 * @field reference_attribute_value The value of the attribute, if any, of the referenced location level, if any
 * @field attribute_units           The unit that attributes are displayed in
 * @field name                      The name of the indicator condition
 * @field value                     The value (1..5) of the indicator condition
 * @field expression                The mathematical expression that must evalutate to TRUE for the condition to be set (or for the rate epxression, if present, to be evaluated)
 * @field rate_expression           The mathematical expression that must evalutate to TRUE for the condition to be set if this is a rate-of-change condition
 * @field minimum_duration          The minimum amount of time that the expression(s) must continuously evaluate to TRUE for condition to be set
 * @field maximum_age               The maximum amount of time that the condition can be considered current
 */
CREATE OR REPLACE FORCE VIEW av_loc_lvl_indicator
AS
    WITH llic
          AS (SELECT    level_indicator_code, level_indicator_value AS VALUE,
                            description AS name,
                            expression || ' ' || comparison_operator_1 || ' ' || ROUND (CAST (comparison_value_1 AS NUMBER), 10) || SUBSTR (' ', 1, LENGTH (connector)) || connector || SUBSTR (' ', 1, LENGTH (comparison_operator_2)) || comparison_operator_2 || SUBSTR (' ', 1, LENGTH (comparison_value_2)) || ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS expression,
                            comparison_unit,
                            rate_expression || SUBSTR (' ', 1, LENGTH (rate_comparison_operator_1)) || rate_comparison_operator_1 || SUBSTR (' ', 1, LENGTH (rate_comparison_value_1)) || ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) || SUBSTR (' ', 1, LENGTH (rate_connector)) || rate_connector || SUBSTR (' ', 1, LENGTH (rate_comparison_operator_2)) || rate_comparison_operator_2 || SUBSTR (' ', 1, LENGTH (rate_comparison_value_2)) || ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_expression,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond),
          unit
          AS (SELECT    unit_code, unit_id
                  FROM    cwms_unit),
          rate_unit
          AS (SELECT    unit_code AS rate_unit_code, unit_id AS rate_unit_id
                  FROM    cwms_unit),
          lli
          AS (SELECT    *
                  FROM    at_loc_lvl_indicator),
          loc
          AS (SELECT    location_code, base_location_code, sub_location_id
                  FROM    at_physical_location),
          base_loc
          AS (SELECT    base_location_code, base_location_id, db_office_code
                  FROM    at_base_location),
          ofc
          AS (SELECT    office_code, office_id
                  FROM    cwms_office),
          param
          AS (SELECT    parameter_code, base_parameter_code, sub_parameter_id
                  FROM    at_parameter),
          base_param
          AS (SELECT    base_parameter_code, base_parameter_id
                  FROM    cwms_base_parameter),
          param_type
          AS (SELECT    parameter_type_code, parameter_type_id
                  FROM    cwms_parameter_type),
          dur
          AS (SELECT    duration_code, duration_id
                  FROM    cwms_duration),
          spec_level
          AS (SELECT    *
                  FROM    at_specified_level),
          attr_param
          AS (SELECT    parameter_code, base_parameter_code, sub_parameter_id
                  FROM    at_parameter),
          attr_base_param
          AS (SELECT    base_parameter_code, base_parameter_id, unit_code
                  FROM    cwms_base_parameter),
          attr_param_type
          AS (SELECT    parameter_type_code, parameter_type_id
                  FROM    cwms_parameter_type),
          attr_dur
          AS (SELECT    duration_code, duration_id
                  FROM    cwms_duration),
          disp
          AS (SELECT    *
                  FROM    at_display_units),
          conv
          AS (SELECT    *
                  FROM    cwms_unit_conversion),
          ref_spec_level
          AS (SELECT    *
                  FROM    at_specified_level)
    SELECT      office_id,
                  base_location_id || SUBSTR ('-', 1, LENGTH (sub_location_id)) || sub_location_id || '.' || base_param.base_parameter_id || SUBSTR ('-', 1, LENGTH (param.sub_parameter_id)) || param.sub_parameter_id || '.' || param_type.parameter_type_id || '.' || dur.duration_id || '.' || spec_level.specified_level_id || '.' || level_indicator_id AS level_indicator_id,
                  ref_spec_level.specified_level_id AS reference_level_id,
                  attr_base_param.base_parameter_id || SUBSTR ('-', 1, LENGTH (attr_param.sub_parameter_id)) || attr_param.sub_parameter_id || SUBSTR ('.', 1, LENGTH (attr_param_type.parameter_type_id)) || attr_param_type.parameter_type_id || SUBSTR ('.', 1, LENGTH (attr_dur.duration_id)) || attr_dur.duration_id AS attribute_id,
                  unit_system,
                  ROUND (nvl(cwms_util.eval_rpn_expression(function, double_tab_t(attr_value)), attr_value), 10 - LOG (10, nvl(cwms_util.eval_rpn_expression(function, double_tab_t(attr_value)), attr_value))) AS attribute_value,
                  ROUND (nvl(cwms_util.eval_rpn_expression(function, double_tab_t(ref_attr_value)), ref_attr_value), 10 - LOG (10, nvl(cwms_util.eval_rpn_expression(function, double_tab_t(ref_attr_value)), ref_attr_value))) AS reference_attribute_value,
                  to_unit_id AS attribute_units, name, VALUE,
                  expression || SUBSTR (' ', 1, LENGTH (unit_id)) || unit_id AS expression,
                  rate_expression || SUBSTR (' ', 1, LENGTH (rate_unit_id)) || rate_unit_id || SUBSTR (' per ', 1, LENGTH (rate_interval)) || SUBSTR (rate_interval, 2) AS rate_expression,
                  SUBSTR (minimum_duration, 2) AS minimum_duration,
                  SUBSTR (maximum_age, 2) AS maximum_age
         FROM   llic
                  JOIN lli
                      ON lli.level_indicator_code = llic.level_indicator_code
                  JOIN loc
                      ON loc.location_code = lli.location_code
                  JOIN base_loc
                      ON base_loc.base_location_code = loc.base_location_code
                  JOIN ofc
                      ON ofc.office_code = base_loc.db_office_code
                  JOIN param
                      ON param.parameter_code = lli.parameter_code
                  JOIN base_param
                      ON base_param.base_parameter_code = param.base_parameter_code
                  JOIN param_type
                      ON param_type.parameter_type_code = lli.parameter_type_code
                  JOIN dur
                      ON dur.duration_code = lli.duration_code
                  JOIN spec_level
                      ON spec_level.specified_level_code = lli.specified_level_code
                  LEFT OUTER JOIN attr_param
                      ON attr_param.parameter_code = lli.attr_parameter_code
                  LEFT OUTER JOIN attr_base_param
                      ON attr_base_param.base_parameter_code =
                              attr_param.base_parameter_code
                  LEFT OUTER JOIN attr_param_type
                      ON attr_param_type.parameter_type_code =
                              lli.attr_parameter_type_code
                  LEFT OUTER JOIN attr_dur
                      ON attr_dur.duration_code = lli.attr_duration_code
                  LEFT OUTER JOIN disp
                      ON disp.parameter_code = attr_base_param.base_parameter_code
                          AND disp.db_office_code = ofc.office_code
                  LEFT OUTER JOIN conv
                      ON conv.from_unit_code = attr_base_param.unit_code
                          AND conv.to_unit_code = disp.display_unit_code
                  LEFT OUTER JOIN ref_spec_level
                      ON ref_spec_level.specified_level_code =
                              lli.ref_specified_level_code
                  LEFT OUTER JOIN unit
                      ON unit.unit_code = llic.comparison_unit
                  LEFT OUTER JOIN rate_unit
                      ON rate_unit.rate_unit_code = llic.rate_comparison_unit
    ORDER BY   office_id,
                  level_indicator_id,
                  reference_level_id,
                  attribute_id,
                  unit_system,
                  attribute_value,
                  VALUE;

/