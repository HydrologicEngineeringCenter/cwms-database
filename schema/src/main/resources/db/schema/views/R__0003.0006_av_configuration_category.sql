/**
 * Displays configuration categories
 *
 * @since CWMS 3.0
 *
 * @field category_id The configuration category
 * @field description A description of the category
 */
create or replace force view av_configuration_category (
   category_id,
   description)
as
select category_id,
       description
  from cwms_config_category;

create or replace public synonym cwms_v_configuration_category for av_configuration_category;
