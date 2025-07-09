create type str_tab_t
/**
 * Holds a collection of strings
 *
 * @see type str_tab_tab_t
 */
is table of varchar2(32767);
/


create or replace public synonym cwms_t_str_tab for str_tab_t;

