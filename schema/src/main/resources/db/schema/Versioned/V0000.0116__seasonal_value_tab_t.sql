create type seasonal_value_tab_t
/**
 * Holds a collection of values at specified offsets into a recurring interval
 *
 * @see type seasonal_value_t
 */
is table of seasonal_value_t;
/


create or replace public synonym cwms_t_seasonal_value_tab for seasonal_value_tab_t;

