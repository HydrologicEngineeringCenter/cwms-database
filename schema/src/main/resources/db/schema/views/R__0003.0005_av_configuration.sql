/**
 * Displays information on configurations
 *
 * @since CWMS 3.0
 *
 * @field office_id               The office that owns the configuration in the database
 * @field configuration_id        The text identifier of the configuration
 * @field parent_configuration_id The text identifier of the parent configuration, if any
 * @field category_id             The category of the configuration
 * @field configuration_name      The configuration name
 * @field configuration_code      The numeric code that idenifies the configuration in the database
 * @field parent_code             The numeric code that identifies the parent configuration in the database
 */
create or replace force view av_configuration (
   office_id,
   configuration_id,
   parent_configuration_id,
   category_id,
   configuration_name,
   configuration_code,
   parent_code)
as
select q1.office_id,
       q1.configuration_id,
       q2.configuration_id as parent_configuration_id,
       q1.category_id,
       q1.configuration_name,
       q1.configuration_code,
       q1.parent_code
from (select o.office_id,
             e.configuration_id,
             e.configuration_code,
             e.parent_code,
             e.category_id,
             e.configuration_name
        from at_configuration e,
             cwms_office o
       where o.office_code = e.office_code
     ) q1
     left outer join
     (select configuration_code,
             configuration_id
        from at_configuration
     ) q2 on q2.configuration_code = q1.parent_code;

create or replace public synonym cwms_v_configuration for av_configuration;
