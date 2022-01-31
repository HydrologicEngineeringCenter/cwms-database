create type rating_conn_map_tab_t
/**
 * Holds connection information for all source ratings for a virtual rating
 *
 * @see type rating_conn_map_t
 */
is table of rating_conn_map_t;
/


create or replace public synonym cwms_t_rating_conn_map_tab for rating_conn_map_tab_t;

