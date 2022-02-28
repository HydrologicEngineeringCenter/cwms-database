/**
 * Displays entity categories
 *
 * @since CWMS 3.0
 *
 * @field category_id The entity category
 * @field description A description of the category
 */

create or replace force view av_entity_category (
   category_id,
   description)
as
select category_id,
       description
  from cwms_entity_category;

begin
	execute immediate 'grant select on av_entity_category to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_entity_category for av_entity_category;
