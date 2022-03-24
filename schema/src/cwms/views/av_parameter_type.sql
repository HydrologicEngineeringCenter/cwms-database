insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_PARAMETER_TYPE', null,'
/**
 * Displays information on parameters
 *
 * @Added after CWMS 21.1.x
 *
 * @field parameter_type_code Unique numeric code identifying the parameter_type
 * @field parameter_id        Parameter type 
 * @field description         The parameter type description
 */
');

create or replace view av_parameter_type(
   parameter_type_code,
   parameter_type_id,
   description
   )
as
   select 
     parameter_type_code,
     parameter_type_id,
     description
     from cwms_parameter_type
/
