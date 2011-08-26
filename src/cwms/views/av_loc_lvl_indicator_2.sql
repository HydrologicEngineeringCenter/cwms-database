--
-- The documentation is too big to fit in a sql string literal (4000 chars max)
--
declare
   doc_clob clob;
   doc_text varchar2(32767) := '
      /**
       * Displays information about location level indicators with each indicator condition in its own set of columns
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
       * @field minimum_duration          The minimum amount of time that the expression(s) must continuously evaluate to TRUE for condition to be set
       * @field maximum_age               The maximum amount of time that the condition can be considered current
       * @field unit_id                   The unit for the condition expressions
       * @field rate_unit_id              The unit for the condition rate expressions, if any
       * @field cond_1_name               The name of the indicator condition 1
       * @field cond_1_expr               The mathematical expression for condition 1. If a rate expression is present, this expression is used to determine if the rate expression will be evaluated; otherwise it is used to determine if condition 1 will be set.
       * @field cond_1_op_1               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 1 for condition 1
       * @field cond_1_val_1              The value used with operator 1 to compare with the result of the expression for condition 1
       * @field cond_1_connector          The logical connector (AND, OR) used to combine the results of the two comparisons, if two comparisons are used for condition 1
       * @field cond_1_op_2               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 2, if two comparisons are used for condition 1
       * @field cond_1_val_2              The value used with operator 2 to compare with the result of the expression, if two comparisons are used for condition 1
       * @field cond_1_rate_expr          The mathematical rate-of-change expression for condition 1
       * @field cond_1_rate_op_1          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with rate value 1 for condition 1
       * @field cond_1_rate_val_1         The value used with rate operator 1 to compare with the result of the rate expression for condition 1
       * @field cond_1_rate_connector     The logical connector (AND, OR) used to combine the results of the two rate comparisons, if two rate comparisons are used for condition 1
       * @field cond_1_rate_op_2          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with value 2, if two rate comparisons are used for condition 1
       * @field cond_1_rate_val_2         The value used with rate operator 2 to compare with the result of the rate expression, if two rate comparisons are used for condition 1
       * @field cond_1_rate_interval      The time interval used to compute the rate value for condition 1
       * @field cond_2_name               The name of the indicator condition 2
       * @field cond_2_expr               The mathematical expression for condition 2. If a rate expression is present, this expression is used to determine if the rate expression will be evaluated; otherwise it is used to determine if condition 2 will be set.
       * @field cond_2_op_1               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 1 for condition 2
       * @field cond_2_val_1              The value used with operator 1 to compare with the result of the expression for condition 2
       * @field cond_2_connector          The logical connector (AND, OR) used to combine the results of the two comparisons, if two comparisons are used for condition 2
       * @field cond_2_op_2               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 2, if two comparisons are used for condition 2
       * @field cond_2_val_2              The value used with operator 2 to compare with the result of the expression, if two comparisons are used for condition 2
       * @field cond_2_rate_expr          The mathematical rate-of-change expression for condition 2
       * @field cond_2_rate_op_1          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with rate value 1 for condition 2
       * @field cond_2_rate_val_1         The value used with rate operator 1 to compare with the result of the rate expression for condition 2
       * @field cond_2_rate_connector     The logical connector (AND, OR) used to combine the results of the two rate comparisons, if two rate comparisons are used for condition 2
       * @field cond_2_rate_op_2          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with value 2, if two rate comparisons are used for condition 2
       * @field cond_2_rate_val_2         The value used with rate operator 2 to compare with the result of the rate expression, if two rate comparisons are used for condition 2
       * @field cond_2_rate_interval      The time interval used to compute the rate value for condition 2
       * @field cond_3_name               The name of the indicator condition 3
       * @field cond_3_expr               The mathematical expression for condition 3. If a rate expression is present, this expression is used to determine if the rate expression will be evaluated; otherwise it is used to determine if condition 3 will be set.
       * @field cond_3_op_1               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 1 for condition 3
       * @field cond_3_val_1              The value used with operator 1 to compare with the result of the expression for condition 3
       * @field cond_3_connector          The logical connector (AND, OR) used to combine the results of the two comparisons, if two comparisons are used for condition 3
       * @field cond_3_op_2               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 2, if two comparisons are used for condition 3
       * @field cond_3_val_2              The value used with operator 2 to compare with the result of the expression, if two comparisons are used for condition 3
       * @field cond_3_rate_expr          The mathematical rate-of-change expression for condition 3
       * @field cond_3_rate_op_1          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with rate value 1 for condition 3
       * @field cond_3_rate_val_1         The value used with rate operator 1 to compare with the result of the rate expression for condition 3
       * @field cond_3_rate_connector     The logical connector (AND, OR) used to combine the results of the two rate comparisons, if two rate comparisons are used for condition 3
       * @field cond_3_rate_op_2          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with value 2, if two rate comparisons are used for condition 3
       * @field cond_3_rate_val_2         The value used with rate operator 2 to compare with the result of the rate expression, if two rate comparisons are used for condition 3
       * @field cond_3_rate_interval      The time interval used to compute the rate value for condition 3
       * @field cond_4_name               The name of the indicator condition 4
       * @field cond_4_expr               The mathematical expression for condition 4. If a rate expression is present, this expression is used to determine if the rate expression will be evaluated; otherwise it is used to determine if condition 4 will be set.
       * @field cond_4_op_1               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 1 for condition 4
       * @field cond_4_val_1              The value used with operator 1 to compare with the result of the expression for condition 4
       * @field cond_4_connector          The logical connector (AND, OR) used to combine the results of the two comparisons, if two comparisons are used for condition 4
       * @field cond_4_op_2               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 2, if two comparisons are used for condition 4
       * @field cond_4_val_2              The value used with operator 2 to compare with the result of the expression, if two comparisons are used for condition 4
       * @field cond_4_rate_expr          The mathematical rate-of-change expression for condition 4
       * @field cond_4_rate_op_1          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with rate value 1 for condition 4
       * @field cond_4_rate_val_1         The value used with rate operator 1 to compare with the result of the rate expression for condition 4
       * @field cond_4_rate_connector     The logical connector (AND, OR) used to combine the results of the two rate comparisons, if two rate comparisons are used for condition 4
       * @field cond_4_rate_op_2          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with value 2, if two rate comparisons are used for condition 4
       * @field cond_4_rate_val_2         The value used with rate operator 2 to compare with the result of the rate expression, if two rate comparisons are used for condition 4
       * @field cond_4_rate_interval      The time interval used to compute the rate value for condition 4
       * @field cond_5_name               The name of the indicator condition 5
       * @field cond_5_expr               The mathematical expression for condition 5. If a rate expression is present, this expression is used to determine if the rate expression will be evaluated; otherwise it is used to determine if condition 5 will be set.
       * @field cond_5_op_1               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 1 for condition 5
       * @field cond_5_val_1              The value used with operator 1 to compare with the result of the expression for condition 5
       * @field cond_5_connector          The logical connector (AND, OR) used to combine the results of the two comparisons, if two comparisons are used for condition 5
       * @field cond_5_op_2               The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the expression with value 2, if two comparisons are used for condition 5
       * @field cond_5_val_2              The value used with operator 2 to compare with the result of the expression, if two comparisons are used for condition 5
       * @field cond_5_rate_expr          The mathematical rate-of-change expression for condition 5
       * @field cond_5_rate_op_1          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with rate value 1 for condition 5
       * @field cond_5_rate_val_1         The value used with rate operator 1 to compare with the result of the rate expression for condition 5
       * @field cond_5_rate_connector     The logical connector (AND, OR) used to combine the results of the two rate comparisons, if two rate comparisons are used for condition 5
       * @field cond_5_rate_op_2          The operator (LT, LE, EQ, NE, GE, GT) used to compare the result of the rate expression with value 2, if two rate comparisons are used for condition 5
       * @field cond_5_rate_val_2         The value used with rate operator 2 to compare with the result of the rate expression, if two rate comparisons are used for condition 5
       * @field cond_5_rate_interval      The time interval used to compute the rate value for condition 5
       */';
begin
   dbms_lob.createtemporary(doc_clob, true);
   dbms_lob.open(doc_clob, dbms_lob.lob_readwrite);
   dbms_lob.writeappend(doc_clob, length(doc_text), doc_text);
   dbms_lob.close(doc_clob);
   insert
     into at_clob
   values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_LVL_INDICATOR_2', null, doc_clob);
end;
/

CREATE OR REPLACE FORCE VIEW av_loc_lvl_indicator_2
AS
    WITH llic1
          AS (SELECT    level_indicator_code, description AS name, expression,
                            comparison_operator_1 AS op_1,
                            ROUND (CAST (comparison_value_1 AS NUMBER), 10) AS val_1,
                            connector, comparison_operator_2 AS op_2,
                            ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS val_2,
                            comparison_unit, rate_expression,
                            rate_comparison_operator_1 AS rate_op_1,
                            ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) AS rate_val_1,
                            rate_connector, rate_comparison_operator_2 AS rate_op_2,
                            ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_val_2,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond
                 WHERE    level_indicator_value = 1),
          llic2
          AS (SELECT    level_indicator_code, description AS name, expression,
                            comparison_operator_1 AS op_1,
                            ROUND (CAST (comparison_value_1 AS NUMBER), 10) AS val_1,
                            connector, comparison_operator_2 AS op_2,
                            ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS val_2,
                            comparison_unit, rate_expression,
                            rate_comparison_operator_1 AS rate_op_1,
                            ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) AS rate_val_1,
                            rate_connector, rate_comparison_operator_2 AS rate_op_2,
                            ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_val_2,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond
                 WHERE    level_indicator_value = 2),
          llic3
          AS (SELECT    level_indicator_code, description AS name, expression,
                            comparison_operator_1 AS op_1,
                            ROUND (CAST (comparison_value_1 AS NUMBER), 10) AS val_1,
                            connector, comparison_operator_2 AS op_2,
                            ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS val_2,
                            comparison_unit, rate_expression,
                            rate_comparison_operator_1 AS rate_op_1,
                            ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) AS rate_val_1,
                            rate_connector, rate_comparison_operator_2 AS rate_op_2,
                            ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_val_2,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond
                 WHERE    level_indicator_value = 3),
          llic4
          AS (SELECT    level_indicator_code, description AS name, expression,
                            comparison_operator_1 AS op_1,
                            ROUND (CAST (comparison_value_1 AS NUMBER), 10) AS val_1,
                            connector, comparison_operator_2 AS op_2,
                            ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS val_2,
                            comparison_unit, rate_expression,
                            rate_comparison_operator_1 AS rate_op_1,
                            ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) AS rate_val_1,
                            rate_connector, rate_comparison_operator_2 AS rate_op_2,
                            ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_val_2,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond
                 WHERE    level_indicator_value = 4),
          llic5
          AS (SELECT    level_indicator_code, description AS name, expression,
                            comparison_operator_1 AS op_1,
                            ROUND (CAST (comparison_value_1 AS NUMBER), 10) AS val_1,
                            connector, comparison_operator_2 AS op_2,
                            ROUND (CAST (comparison_value_2 AS NUMBER), 10) AS val_2,
                            comparison_unit, rate_expression,
                            rate_comparison_operator_1 AS rate_op_1,
                            ROUND (CAST (rate_comparison_value_1 AS NUMBER), 10) AS rate_val_1,
                            rate_connector, rate_comparison_operator_2 AS rate_op_2,
                            ROUND (CAST (rate_comparison_value_2 AS NUMBER), 10) AS rate_val_2,
                            rate_comparison_unit, rate_interval
                  FROM    at_loc_lvl_indicator_cond
                 WHERE    level_indicator_value = 5),
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
                  ROUND (attr_value * factor + offset, 10 - LOG (10, attr_value * factor + offset)) AS attribute_value,
                  ROUND (ref_attr_value * factor + offset, 10 - LOG (10, ref_attr_value * factor + offset)) AS reference_attribute_value,
                  to_unit_id AS attribute_units,
                  SUBSTR (minimum_duration, 2) AS minimum_duration,
                  SUBSTR (maximum_age, 2) AS maximum_age, unit_id, rate_unit_id,
                  llic1.name AS cond_1_name, llic1.expression AS cond_1_expr,
                  llic1.op_1 AS cond_1_op_1, llic1.val_1 AS cond_1_val_1,
                  llic1.connector AS cond_1_connector, llic1.op_2 AS cond_1_op_2,
                  llic1.val_2 AS cond_1_val_2,
                  llic1.rate_expression AS cond_1_rate_expr,
                  llic1.rate_op_1 AS cond_1_rate_op_1,
                  llic1.rate_val_1 AS cond_1_rate_val_1,
                  llic1.rate_connector AS cond_1_rate_connector,
                  llic1.rate_op_2 AS cond_1_rate_op_2,
                  llic1.rate_val_2 AS cond_1_rate_val_2,
                  llic1.rate_interval AS cond_1_rate_interval,
                  llic2.name AS cond_2_name, llic2.expression AS cond_2_expr,
                  llic2.op_1 AS cond_2_op_1, llic2.val_1 AS cond_2_val_1,
                  llic2.connector AS cond_2_connector, llic2.op_2 AS cond_2_op_2,
                  llic2.val_2 AS cond_2_val_2,
                  llic2.rate_expression AS cond_2_rate_expr,
                  llic2.rate_op_1 AS cond_2_rate_op_1,
                  llic2.rate_val_1 AS cond_2_rate_val_1,
                  llic2.rate_connector AS cond_2_rate_connector,
                  llic2.rate_op_2 AS cond_2_rate_op_2,
                  llic2.rate_val_2 AS cond_2_rate_val_2,
                  llic2.rate_interval AS cond_2_rate_interval,
                  llic3.name AS cond_3_name, llic3.expression AS cond_3_expr,
                  llic3.op_1 AS cond_3_op_1, llic3.val_1 AS cond_3_val_1,
                  llic3.connector AS cond_3_connector, llic3.op_2 AS cond_3_op_2,
                  llic3.val_2 AS cond_3_val_2,
                  llic3.rate_expression AS cond_3_rate_expr,
                  llic3.rate_op_1 AS cond_3_rate_op_1,
                  llic3.rate_val_1 AS cond_3_rate_val_1,
                  llic3.rate_connector AS cond_3_rate_connector,
                  llic3.rate_op_2 AS cond_3_rate_op_2,
                  llic3.rate_val_2 AS cond_3_rate_val_2,
                  llic3.rate_interval AS cond_3_rate_interval,
                  llic4.name AS cond_4_name, llic4.expression AS cond_4_expr,
                  llic4.op_1 AS cond_4_op_1, llic4.val_1 AS cond_4_val_1,
                  llic4.connector AS cond_4_connector, llic4.op_2 AS cond_4_op_2,
                  llic4.val_2 AS cond_4_val_2,
                  llic4.rate_expression AS cond_4_rate_expr,
                  llic4.rate_op_1 AS cond_4_rate_op_1,
                  llic4.rate_val_1 AS cond_4_rate_val_1,
                  llic4.rate_connector AS cond_4_rate_connector,
                  llic4.rate_op_2 AS cond_4_rate_op_2,
                  llic4.rate_val_2 AS cond_4_rate_val_2,
                  llic4.rate_interval AS cond_4_rate_interval,
                  llic5.name AS cond_5_name, llic5.expression AS cond_5_expr,
                  llic5.op_1 AS cond_5_op_1, llic5.val_1 AS cond_5_val_1,
                  llic5.connector AS cond_5_connector, llic5.op_2 AS cond_5_op_2,
                  llic5.val_2 AS cond_5_val_2,
                  llic5.rate_expression AS cond_5_rate_expr,
                  llic5.rate_op_1 AS cond_5_rate_op_1,
                  llic5.rate_val_1 AS cond_5_rate_val_1,
                  llic5.rate_connector AS cond_5_rate_connector,
                  llic5.rate_op_2 AS cond_5_rate_op_2,
                  llic5.rate_val_2 AS cond_5_rate_val_2,
                  llic5.rate_interval AS cond_5_rate_interval
         FROM   llic1
                  JOIN llic2
                      ON llic2.level_indicator_code = llic1.level_indicator_code
                  JOIN llic3
                      ON llic3.level_indicator_code = llic1.level_indicator_code
                  JOIN llic4
                      ON llic4.level_indicator_code = llic1.level_indicator_code
                  JOIN llic5
                      ON llic5.level_indicator_code = llic1.level_indicator_code
                  JOIN lli
                      ON lli.level_indicator_code = llic1.level_indicator_code
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
                      ON unit.unit_code = llic1.comparison_unit
                  LEFT OUTER JOIN rate_unit
                      ON rate_unit.rate_unit_code = llic1.rate_comparison_unit
    ORDER BY   office_id,
                  level_indicator_id,
                  reference_level_id,
                  attribute_id,
                  unit_system,
                  attribute_value;

/