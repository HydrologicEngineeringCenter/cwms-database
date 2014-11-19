create type double_tab_tab_t
/**
 * Holds a collection of collections of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_t
 */
is table of double_tab_t;
/


create or replace public synonym cwms_t_double_tab_tab_t for double_tab_tab_t;

