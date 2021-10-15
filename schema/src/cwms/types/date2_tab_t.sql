create type date2_tab_t
/**
 * Holds a collection of date pairs
 *
 * @see type date2_t
 */
as table of date2_t;
/


create or replace public synonym cwms_t_date2_tab for date2_tab_t;

