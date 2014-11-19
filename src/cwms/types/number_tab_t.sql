create type number_tab_t
/**
 * Holds a collection of integer or floating point numeric values
 *
 * @see type double_tab_t
 */
is table of number;
/


create or replace public synonym cwms_t_number_tab for number_tab_t;

