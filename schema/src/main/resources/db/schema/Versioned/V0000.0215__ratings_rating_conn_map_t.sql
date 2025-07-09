create type rating_conn_map_t
/**
 * Holds connection information for a single source rating for a virtual rating
 *
 */ 
as object(
   ind_params str_tab_t, 
   dep_param  varchar2(4),
   units      str_tab_t,
   functions  str_tab_t
);
/


create or replace public synonym cwms_t_rating_conn_map for rating_conn_map_t;

