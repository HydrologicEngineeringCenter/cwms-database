create type number_tab_tab_t
/**
 * Holds a collection of integer or floating point numeric values
 *
 * @see type double_tab_tab_t
 */
is table of number_tab_t;
/


create or replace public synonym cwms_t_number_tab_tab for number_tab_tab_t;

