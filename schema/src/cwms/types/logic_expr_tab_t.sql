CREATE TYPE logic_expr_tab_t
/**
 * Hold a collection of logic_expr_t objects
 *
 * @see type logic_expr_t
 */
IS
  TABLE OF logic_expr_t;
/


create or replace public synonym cwms_t_logic_expr_tab for logic_expr_tab_t;

