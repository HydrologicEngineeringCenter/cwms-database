/**
 * Contains information for converting USGS parameters to CWMS
 *
 * @since CWMS 2.2
 *
 * @member office_id           The office that owns the conversion
 * @member usgs_parameter_code The 5-digit USGS parameter code to convert
 * @member parameter_id        The CWMS Parameter
 * @member parameter_type_id   The CWMS Parameter Type
 * @member unit_id             The CWMS Unit
 * @member factor              CWMS = USGS * factor + offset
 * @member offset              CWMS = USGS * factor + offset
 */
create or replace force view av_usgs_parameter(
   office_id,
   usgs_parameter_code,
   parameter_id,
   parameter_type_id,
   unit_id,
   factor,
   offset)
as
   select o.office_id,
          to_char(up.usgs_parameter_code, '00009') as usgs_parameter_code,
          case
             when p.sub_parameter_id is null then bp.base_parameter_id
             else bp.base_parameter_id || '-' || p.sub_parameter_id
          end
             as parameter_id,
          pt.parameter_type_id,
          u.unit_id,
          up.factor,
          up.offset
     from at_usgs_parameter up,
          at_parameter p,
          cwms_base_parameter bp,
          cwms_parameter_type pt,
          cwms_unit u,
          cwms_office o
    where o.office_code = up.office_code
      and p.parameter_code = up.cwms_parameter_code
      and bp.base_parameter_code = p.base_parameter_code
      and pt.parameter_type_code = up.cwms_parameter_type_code
      and u.unit_code = up.cwms_unit_code
/

create or replace public synonym cwms_v_usgs_parameter for av_usgs_parameter
/