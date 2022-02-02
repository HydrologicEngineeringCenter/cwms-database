create or replace type ts_extents_tab_t
/**
 * Holds date/time and value extent information for time series (basically at_ts_extents%rowtype)
 *
 * @see ts_extents_t
 *
 */
as table of ts_extents_t;
/

create or replace public synonym cwms_t_ts_extents_tab for ts_extents_tab_t;
