create type str_tab_tab_t
/**
 * Holds a collection of string collections
 *
 * @see type str_tab_t
 */
is table of str_tab_t;
/


create or replace public synonym cwms_t_str_tab_tab for str_tab_tab_t;

