insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_LVL_CUR_MAX_IND', null,
'
/**
 * Displays the current maximum location level indicator that is set for each time series
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
');
create or replace force view av_loc_lvl_cur_max_ind (
   office_id,
   cwms_ts_id,
   level_indicator_id,
   attribute_id,
   attribute_value,
   max_indicator,
   indicator_name
)
as
select * from table(cwms_cat.cat_loc_lvl_cur_max_ind)
/
