/**
 * Contains USGS parameters and their corresponding CWMS and SHEF parameters
 *
 * @since CWMS 3.0
 *
 * @member usgs_parameter_code    The USGS parameter as an integer
 * @member usgs_parameter_id      The USGS parameter as a five-digit string
 * @member base_parameter_id      The corrseponding CWMS base parameter id
 * @member sub_parameter_id       The corrseponding CWMS sub-parameter id, if any
 * @member parameter_id           The corrseponding full CWMS parameter id
 * @member parameter_type_id      The corresponding CWMS parameter type
 * @member unit_id                The corrseponding CWMS unit id
 * @member cwms_conversion_factor Factor in CWMS = USGS * factor + offset
 * @member cwms_conversion_offset Offset in CWMS = USGS * factor + offset
 * @member shef_physical_element  The corresponding SHEF PE code, if any
 * @member shef_unit_is_english   Whether the SHEF unit is english (T = /DUE (optional), F = /DUS (required))
 * @member shef_conversion_factor Factor in SHEF = USGS * factor + offset
 * @member shef_conversion_offset Offset in SHEF = USGS * factor + offset
 * @member usgs_parameter_name    The parameter name as specified by the USGS
 * @member cwms_parameter_name    The parameter name according to the CWMS base parameter description + sub-parameter id
 */
create or replace force view av_usgs_parameter_all (
   usgs_parameter_code,
   usgs_parameter_id,
   base_parameter_id,
   sub_parameter_id,
   parameter_id,
   parameter_type_id,
   unit_id,
   cwms_conversion_factor,
   cwms_conversion_offset,
   shef_physical_element,
   shef_unit_is_english,
   shef_conversion_factor,
   shef_conversion_offset,
   usgs_parameter_name,
   cwms_parameter_name)
as
select usgs_parameter_code,
       lpad(to_char(up.usgs_parameter_code), 5, '0') as usgs_parameter_id,
       bp.base_parameter_id,
       up.cwms_sub_parameter_id as sub_parameter_id,
       bp.base_parameter_id
       ||substr('-', 1, length(up.cwms_sub_parameter_id))
       ||up.cwms_sub_parameter_id as parameter_id,
       pt.parameter_type_id,
       cu.unit_id,
       up.cwms_conversion_factor,
       up.cwms_conversion_offset,
       up.shef_physical_element,
       up.shef_unit_is_english,
       up.shef_conversion_factor,
       up.shef_conversion_offset,
       up.usgs_parameter_name,
       bp.description
       ||substr(' - ', 1, length(up.cwms_sub_parameter_id))
       ||cwms_sub_parameter_id as cwms_parameter_name
  from cwms_usgs_parameter up,
       cwms_base_parameter bp,
       cwms_parameter_type pt,
       cwms_unit cu
 where bp.base_parameter_code = up.cwms_base_parameter_code
   and pt.parameter_type_code = up.cwms_parameter_type_code
   and cu.unit_code = up.cwms_unit_code;
/

create or replace public synonym cwms_v_usgs_parameter_all for av_usgs_parameter_all;
commit;
