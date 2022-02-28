create type loc_lvl_indicator_tab_t
/**
 * Holds a collection of loc_lvl_indicator_t objects.
 *
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_t;
/


create or replace public synonym cwms_t_loc_lvl_indicator_tab for loc_lvl_indicator_tab_t;

