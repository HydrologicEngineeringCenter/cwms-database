create type fcst_location_t
/**
 * A forecast location and its sort order.
 *
 * @param location_id The location identifier.
 * @param sort_order  The sort order. -1 for primary.
 */
as object (
   location_id varchar2(256),
   sort_order  number
);
/

create or replace public synonym cwms_t_fcst_location for fcst_location_t;
