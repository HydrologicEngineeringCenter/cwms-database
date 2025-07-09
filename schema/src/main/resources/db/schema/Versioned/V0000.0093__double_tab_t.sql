create type double_tab_t
/**
 * Holds a collection of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_tab_t
 * @see type number_tab_t
 */
is table of binary_double;
/


create or replace public synonym cwms_t_double_tab for double_tab_t;

