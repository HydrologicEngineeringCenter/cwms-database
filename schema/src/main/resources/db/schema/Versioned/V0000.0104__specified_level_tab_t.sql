create type specified_level_tab_t
/**
 * Holds a collection of specified levels
 *
 * @see type specified_level_t
 */
is table of specified_level_t;
/


create or replace public synonym cwms_t_specified_level_tab for specified_level_tab_t;

