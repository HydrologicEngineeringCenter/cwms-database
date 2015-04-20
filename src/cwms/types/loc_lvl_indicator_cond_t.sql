create type loc_lvl_indicator_cond_t
/**
 * Holds information about a location level indicator condition.  A location level
 * indicator condition is a condition that must evalutate to TRUE for the encompassing
 * indicator to be set. The condition may be an absolute magnitude conition or a
 * rate of change condition. If the condition is a rate of change condition, the
 * absolute magnitude portion is treated as a preliminary test to determine whether
 * the rate of change should be evaluated.  In this case a condition may evalutate
 * to FALSE even if the rate of change portion would evaluate to TRUE because the
 * preliminary test (absolute magnitued portion) evaluated to FALSE. <bold>Do not use
 * the default constructor to create objects of this type since several transient
 * fields need to be computed from specified values.</bold>
 *
 * @see type loc_lvl_ind_cond_tab_t
 *
 * @member indicator_value            The value (1..5) of the indicator
 * @member expression                 A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two absolute magnitude values.
 * @member comparison_operator_1      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the first comparison value
 * @member comparison_value_1         The first (required) comparison value used to compare with the expression
 * @member comparison_unit            The unit of the comparison value(s)
 * @member connector                  The logical operator (AND, OR) used to connect the first and second comparisons if two comparisons are used
 * @member comparison_operator_2      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the second comparison value if two comparisons are used
 * @member comparison_value_2         The second (optional) comparison value used to compare with the expression
 * @member rate_expression            A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two rate-of-change values. Optional. Only evaluated if the absolute magnitude comparison(s) evaluate(s) to true
 * @member rate_comparison_operator_1 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the first rate comparison value
 * @member rate_comparison_value_1    The first comparison value used to compare with the rate expression. Required if a rate expression is used.
 * @member rate_comparison_unit       The unit of the rate comparison value(s)
 * @member rate_connector             The logical operator (AND, OR) used to connect the first and second rate comparisons if two rate comparisons are used
 * @member rate_comparison_operator_2 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the second rate comparison value if two rate comparisons are used
 * @member rate_comparison_value_2    The second comparison value used to compare with the rate expression if two rate comparisons are used
 * @member rate_interval              The time interval used in computing the rate of change
 * @member description                A description of the location level indicator
 * @member factor                     The unit conversion factor for absolute magnitude comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member offset                     The unit conversion offset for absolute magnitude comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member rate_factor                The unit conversion factor for rate of change comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member rate_offset                The unit conversion offset for rate of change comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member interval_factor            A conversion factor to convert from data interval to the specified rate interval. <bold>Transient</bold>
 * @member uses_reference             A flag (T or F) that specifes whether the indicator references a second location level. <bold>Transient</bold>
 * @member expression_tokens          A tokenized version of the absolute magnitude expression. <bold>Transient</bold>
 * @member rate_expression_tokens     A tokenized version of the rate expression. <bold>Transient</bold>
 */
is object
(
   indicator_value            number(1),
   expression                 varchar2(64),
   comparison_operator_1      varchar2(2),
   comparison_value_1         binary_double,
   comparison_unit            number(10),
   connector                  varchar2(3),
   comparison_operator_2      varchar2(2),
   comparison_value_2         binary_double,
   rate_expression            varchar2(64),
   rate_comparison_operator_1 varchar2(2),
   rate_comparison_value_1    binary_double,
   rate_comparison_unit       number(10),
   rate_connector             varchar2(3),
   rate_comparison_operator_2 varchar2(2),
   rate_comparison_value_2    binary_double,
   rate_interval              interval day(3) to second(0),
   description                varchar2(256),
   factor                     binary_double,
   offset                     binary_double,
   rate_factor                binary_double,
   rate_offset                binary_double,
   interval_factor            binary_double,
   uses_reference             varchar2(1),
   expression_tokens          str_tab_t,
   rate_expression_tokens     str_tab_t,
   /**
    * Constructs a loc_lvl_indicator_cond_t object.  <bold>Use this constructor instead
    * of the default constructor when building an object from components</bold>.
    *
    * @param p_indicator_value            The value (1..5) of the indicator
    * @param p_expression                 A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two absolute magnitude values.
    * @param p_comparison_operator_1      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the first comparison value
    * @param p_comparison_value_1         The first (required) comparison value used to compare with the expression
    * @param p_comparison_unit            The unit of the comparison value(s)
    * @param p_connector                  The logical operator (AND, OR) used to connect the first and second comparisons if two comparisons are used
    * @param p_comparison_operator_2      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the second comparison value if two comparisons are used
    * @param p_comparison_value_2         The second (optional) comparison value used to compare with the expression
    * @param p_rate_expression            A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two rate-of-change values. Optional. Only evaluated if the absolute magnitude comparison(s) evaluate(s) to true
    * @param p_rate_comparison_operator_1 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the first rate comparison value
    * @param p_rate_comparison_value_1    The first comparison value used to compare with the rate expression. Required if a rate expression is used.
    * @param p_rate_comparison_unit       The unit of the rate comparison value(s)
    * @param p_rate_connector             The logical operator (AND, OR) used to connect the first and second rate comparisons if two rate comparisons are used
    * @param p_rate_comparison_operator_2 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the second rate comparison value if two rate comparisons are used
    * @param p_rate_comparison_value_2    The second comparison value used to compare with the rate expression if two rate comparisons are used
    * @param p_rate_interval              The time interval used in computing the rate of change
    * @param p_description                A description of the location level indicator
    */
   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result,
   -- not documented
   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result,
   -- not documented
   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2),
   /**
    * Stores a loc_lvl_indicator_cont_t object to the AT_LOC_LEVL_INDICATOR_COND table
    */
   member procedure store(
      p_level_indicator_code in number),  
   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   /**
    * Evaluates the condition's expression and returns the result
    *
    * param p_value   The value (expression variable V) in the object's comparison unit,
    * param p_level   The level value (expression variable L or L1) in the object's comparison unit,
    * param p_level_2 The referenced level value (expression variable L2) in the object's comparison unit, if a referenced location level is used
    *
    * return The numeric result of evaluation the expression
    */
   member function eval_expression(      
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double)
   return binary_double,
   /**
    * Evaluates the condition's rate expression and returns the result
    *
    * param p_rate The rate of change (expression variable R) in the object's rate comparison unit
    *
    * return The numeric result of evaluation the rate expression
    */
   member function eval_rate_expression(      
      p_rate in binary_double)
   return binary_double,
   /**
    * Tests whether the specified parameters cause the location level indicator condition
    * to be set
    *
    * param p_value   The value (expression variable V) in the object's comparison unit,
    * param p_level   The level value (expression variable L or L1) in the object's comparison unit,
    * param p_level_2 The referenced level value (expression variable L2) in the object's comparison unit, if a referenced location level is used
    * param p_rate    The rate of change (expression variable R) in the object's rate comparison unit, if a rate expression is used
    *
    * return whether the specified parameters cause the location level indicator
    *        condition to be set
    */
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
);
/


create or replace public synonym cwms_t_loc_lvl_indicator_cond for loc_lvl_indicator_cond_t;

