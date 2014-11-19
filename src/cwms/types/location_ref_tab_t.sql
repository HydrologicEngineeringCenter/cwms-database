create type location_ref_tab_t
/**
 * Holds a collection of location references.
 *
 * @see type location_ref_t
 */
is table of location_ref_t;
/


create or replace public synonym cwms_t_location_ref_tab for location_ref_tab_t;

