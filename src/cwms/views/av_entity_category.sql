------------------------
-- AV_ENTITY_CATEGORY --
------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_ENTITY_CATEGORY', null,
'
/**
 * Displays entity categories
 *
 * @since CWMS 3.0
 *
 * @field category_id The entity category
 * @field description A description of the category
 */
');
create or replace force view av_entity_category (
   category_id,
   description)
as
select category_id,
       description
  from cwms_entity_category;

grant select on av_entity_category to cwms_user;

create or replace public synonym cwms_v_entity_category for av_entity_category;

