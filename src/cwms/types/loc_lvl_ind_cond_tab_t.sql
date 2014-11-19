create type loc_lvl_ind_cond_tab_t
/**
 * A collectiion of location level indicator conditions
 *
 * @see type loc_lvl_indicator_cond_t
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_cond_t;
/


create or replace public synonym cwms_t_loc_lvl_ind_cond_tab for loc_lvl_ind_cond_tab_t;

