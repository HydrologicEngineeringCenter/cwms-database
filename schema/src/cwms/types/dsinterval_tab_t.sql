create type dsinterval_tab_t
/**
 * Type suitable for holding multiple interval day to second values
 */
as table of interval day to second;
/


create or replace public synonym cwms_t_dsinterval_tab for dsinterval_tab_t;

