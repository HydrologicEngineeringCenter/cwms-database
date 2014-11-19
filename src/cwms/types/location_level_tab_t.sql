create type location_level_tab_t
/**
 * Holds a collection of location levels
 *
 * @see type location_level_t
 */
is table of location_level_t;
/


create or replace public synonym cwms_t_location_level_tab for location_level_tab_t;

