create index at_loc_lvl_indicator_u1 on at_loc_lvl_indicator (
   location_code,
   specified_level_code,
   parameter_code,
   duration_code,
   level_indicator_id,
   cwms_rounding.round_f(attr_value, 12),
   attr_parameter_code,
   ref_specified_level_code,
   ref_attr_value);
---------------------------------------------------------
@@cwms/views/av_basin.sql
@@cwms/views/av_loc.sql
@@cwms/views/av_loc2.sql
@@cwms/views/av_log_message.sql
@@cwms/views/av_stream.sql
@@cwms/views/av_stream_location.sql
@@cwms/views/av_ts_alias.sql
@@cwms/views/av_ts_grp_assgn.sql
@@cwms/views/av_ts_cat_grp.sql
@@cwms/views/av_loc_lvl_attribute.sql
@@cwms/views/av_loc_lvl_ts_map.sql
@@cwms/views/av_loc_lvl_cur_max_ind.sql
@@cwms/views/av_embankment.sql
@@cwms/views/av_embank_protection_type.sql
@@cwms/views/av_embank_structure_type.sql
---------------------------------------------------------
COMMIT;                                                                                                                                                     
