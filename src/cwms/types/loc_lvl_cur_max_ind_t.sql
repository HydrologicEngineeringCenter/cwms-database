create type loc_lvl_cur_max_ind_t
/**
 * Holds a record for AV_LOC_LVL_CUR_MAX_IND view.
 *
 * @since CWMS 2.1
 *
 * @field office_id          Identifies the office that owns the time series
 * @field cwms_ts_id         Identifies the time series
 * @field level_indicator_id Identifies the location level indicator
 * @field attribute_id       Identifies the attribute, if any
 * @field attribute_value    The value of the specified attribute
 * @field max_indicator      The maximum indicator that is currently set
 * @field indicator_name     The name of the indicator
 */
as object(
   office_id          varchar2(16),
   cwms_ts_id         varchar2(183),
   level_indicator_id varchar2(423),
   attribute_id       varchar2(83),
   attribute_value    number,
   max_indicator      number,
   indicator_name     varchar2(256));
/


create or replace public synonym cwms_t_loc_lvl_cur_max_ind for loc_lvl_cur_max_ind_t;

