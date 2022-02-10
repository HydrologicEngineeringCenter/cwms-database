create unique index at_loc_lvl_indicator_u1 on at_loc_lvl_indicator (
   location_code,
   specified_level_code,
   parameter_code,
   duration_code,
   level_indicator_id,
   ${CWMS_SCHEMA}.cwms_rounding.round_f(attr_value,12),
   attr_parameter_code,
   ref_specified_level_code,
   ref_attr_value);
---------------------------------------------------------
