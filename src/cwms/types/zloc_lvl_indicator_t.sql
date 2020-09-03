create type zloc_lvl_indicator_t
-- not documented
is object
(
   level_indicator_code     number(14),
   location_code            number(14),
   specified_level_code     number(14),
   parameter_code           number(14),
   parameter_type_code      number(14),
   duration_code            number(14),
   attr_value               number,
   attr_parameter_code      number(14),
   attr_parameter_type_code number(14),
   attr_duration_code       number(14),
   ref_specified_level_code number(14),
   ref_attr_value           number,
   level_indicator_id       varchar2(32),
   minimum_duration         interval day to second,
   maximum_age              interval day to second,
   conditions               loc_lvl_ind_cond_tab_t,

   constructor function zloc_lvl_indicator_t
      return self as result,

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,

   member procedure store
);
/


create or replace public synonym cwms_t_zloc_lvl_indicator for zloc_lvl_indicator_t;

