create type clob_tab_t
/**
 * Holds a collection of CLOBs
 */
is table of clob;
/


create or replace public synonym cwms_t_clob_tab for clob_tab_t;

