create type fcst_location_tab_t
/**
 * A collection of forecast locations and their sort orders.
 *
 * @see type fcst_location_t
 */
is table of fcst_location_t;
/

create or replace public synonym cwms_t_fcst_location_tab for fcst_location_tab_t;
