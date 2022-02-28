/**
 * Displays information on parameters
 *
 * @since CWMS 2.0, modified in CWMS 2.1
 *
 * @field db_office_id        Office that owns the parameter
 * @field db_office_code      Unique numeric code identifying the office that owns the parameter
 * @field parameter_code      Unique numeric code identifying the parameter
 * @field base_parameter_code Unique numeric code identifying the base parameter
 * @field base_parameter_id   The base parameter
 * @field sub_parameter_id    The sub-parameter, if any
 * @field parameter_id        The full parameter
 * @field description         The parameter description
 * @field has_values          Specifies if the parameter can be used for items that contain values (e.g., time series, ratings)
 */
create or replace view av_parameter(
   db_office_id,
   db_office_code,
   parameter_code,
   base_parameter_code,
   base_parameter_id,
   sub_parameter_id,
   parameter_id,
   description,
   has_values)
as
   select o.office_id db_office_id,
          p.db_office_code,
          p.parameter_code,
          b.base_parameter_code,
          b.base_parameter_id,
          p.sub_parameter_id,
          b.base_parameter_id || substr('-', 1, length(p.sub_parameter_id)) || p.sub_parameter_id parameter_id,
          nvl(p.sub_parameter_desc, b.long_name) as description,
          case
             when p.parameter_code < 0 then 'F'
             else 'T'
          end as has_values
     from cwms_office o, at_parameter p, cwms_base_parameter b
    where p.db_office_code = o.db_host_office_code and p.base_parameter_code = b.base_parameter_code
/