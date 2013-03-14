create index at_loc_lvl_indicator_u1 on at_loc_lvl_indicator (
   location_code,
   specified_level_code,
   parameter_code,
   duration_code,
   level_indicator_id,
   cwms_rounding.round_nn_f(attr_value, '9999999999'),
   attr_parameter_code,
   ref_specified_level_code,
   ref_attr_value);
---------------------------------------------------------
@@cwms/views/av_loc.sql
@@cwms/views/av_log_message.sql
@@cwms/views/av_ts_alias.sql
@@cwms/views/av_ts_grp_assgn.sql
@@cwms/views/av_ts_cat_grp.sql
@@cwms/views/av_loc_lvl_ts_map.sql
@@cwms/views/av_loc_lvl_cur_max_ind.sql
---------------------------------------------------------
COMMIT;                                                                                                                                                     
