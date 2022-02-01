create type logic_expr_t
/**
 * Holds a logic expression that can be evaluated to TRUE or FALSE. The logic operator (combinator), if any,
 * is included in the super-type. Logic expressions may be combination expressions (with operators NOT, AND, XOR, and OR) or comparison expressions (without any operator).
 * Comparison expressions are comprised of two arithmetic expressions from simple constants to complex formulae and one comparison operator (comparitor).
 *
 * @member operand_1  The first sub-expression for binary operators (AND, XOR, OR) and the only one for the unary operator (NOT). Used only if this expression contains an operator.
 * @member operand_2  The second sub-expression for binary operators (AND, XOR, OR). Used only if this expression contains an operator.
 * @member expression The comparison expression to be evaluated if this expression does not contain a combinator
 *
 * @see type abs_logic_expr
 * @see variable cwms_util.combinators
 * @see variable cwms_util.comparitors
 *
 */
under abs_logic_expr_t (
-- operator   varchar2(3),
   operand_1  abs_logic_expr_t,
   operand_2  abs_logic_expr_t,
   expression str_tab_tab_t,

   /**
    * Constructs a logic expression object from a text expression.
    *
    * @param p_expr The logic expression in infix (algebraic) or postfix (RPN) notation.
    */
   constructor function logic_expr_t(
      p_expr in varchar2)
      return self as result,
   /**
    * Constructs a logic expression object from its tokenized form.
    *
    * @param p_table The logic expression tokens. This table is consumed during object creation and has length of zero afterward.
    *
    * @see cwms_util.tokenize_logic_expression
    */
   constructor function logic_expr_t(
      p_table in out nocopy str_tab_tab_t)
      return self as result,
   /**
    * Evaluates the logic expression given specific arguments arg1..argN. This evaluation uses the short-circuit behavior of PL/SQL
    * logic operators. The first expression of any operator is always evaluated.  The second expression of binary operators will
    * not be evaluated if it cannot affect the outcome.
    *
    * @param p_args the actual values to use for arg1...argN. Values are assigned
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...
    *
    * @return TRUE or FALSE
    *
    * @see cwms_util.eval_expression
    */
   overriding member function evaluate(
      p_args   in double_tab_t,
      p_args_offset in integer default 0)
      return boolean,
   /**
    * Uses the DBMS_OUTPUT package to output a schematic of the evaluation tree
    *
    * @param p_level Depth of the outermost operator. Used for recursive calls only.
    */
   overriding member procedure print(
      p_level in integer default 0),

   overriding member function to_algebraic(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_algebraic(
      p_expr in out nocopy varchar2),

   overriding member function to_rpn(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_rpn(
      p_expr in out nocopy varchar2),

   overriding member function to_xml_text(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_xml_text(
      p_expr in out nocopy varchar2)
);


create or replace public synonym cwms_t_logic_expr for logic_expr_t;
