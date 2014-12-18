create type abs_logic_expr_t
/**
 * Holds an abstract logic expression.  This type is used only to allow the sub-type to be recursively defined.
 *
 * @member operator The logic operator (combinator) for this expression, if it has one
 *
 * @see type logic_expr_t
 * @see variable cwms_util.combinators
 *
 */ 
as object(
   operator varchar2(3),

   member function evaluate(
      p_args   in double_tab_t,
      p_args_offset in integer default 0)
      return boolean,
      
   member procedure print(
      p_level in integer default 0),
      
   member function to_algebraic( 
      self in out nocopy abs_logic_expr_t)
      return varchar2,
   
   member procedure to_algebraic(
      p_expr in out nocopy varchar2),
   
   member function to_rpn( 
      self in out nocopy abs_logic_expr_t)
      return varchar2,       
   
   member procedure to_rpn(
      p_expr in out nocopy varchar2),
   
   member function to_xml_text return varchar2
) not final;
/
show errors;

create or replace public synonym cwms_t_abs_logic_expr for abs_logic_expr_t;
