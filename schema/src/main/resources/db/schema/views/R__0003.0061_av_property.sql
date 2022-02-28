/**
 * Displays information on properties
 *
 * @since CWMS 2.1
 *
 * @field office_id     Office that owns the property
 * @field prop_category The property category, analogous to the name of a property file
 * @field prop_id       The property identifier, analogous to the property key in a property file
 * @field prop_value    The property value
 * @field prop_comment  An optional comment or description of the property
 */
create or replace force view av_property(
   office_id,
   prop_category,
   prop_id,
   prop_value,
   prop_comment)
as
   select office_id,
          prop_category,
          prop_id,
          prop_value,
          prop_comment
     from cwms_office o, at_properties p
    where o.office_code = p.office_code
/
