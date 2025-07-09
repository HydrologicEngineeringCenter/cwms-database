create type ts_alias_tab_t
/**
 * Holds information about a collection of time series aliases.  This information
 * doesn't contain any context for the aliases.
 *
 * @see ts_alias_t
 * @see cwms_ts.assign_ts_groups
 */
IS TABLE OF ts_alias_t;
/


create or replace public synonym cwms_t_ts_alias_tab for ts_alias_tab_t;

