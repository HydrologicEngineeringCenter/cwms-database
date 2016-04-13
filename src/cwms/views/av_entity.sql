---------------
-- AV_ENTITY --
---------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_ENTITY', null,
'
/**
 * Displays information on water user contracts
 *
 * @since CWMS 3.0
 *
 * @field office_id        The office that owns the entity in the database
 * @field entity_id        The text identifier of the entity
 * @field parent_entity_id The text identifier of the parent entity, if any
 * @field category_id      The category of the entity
 * @field entity_name      The entity name
 * @field entity_code      The numeric code that idenifies the entity in the database
 * @field parent_code      The numeric code that identifies the parent entity in the database 
 */
');
create or replace force view av_entity (
   office_id,                                       
   entity_id, 
   parent_entity_id, 
   category_id, 
   entity_name,
   entity_code,
   parent_code)
as 
select q1.office_id,
     q1.entity_id,
     q2.entity_id as parent_entity_id,
     q1.category_id,
     q1.entity_name,
     q1.entity_code,
     q1.parent_code
from (select o.office_id,
             e.entity_id,
             e.entity_code,
             e.parent_code,                                       
             e.category_id,
             e.entity_name
        from at_entity e,
             cwms_office o
       where o.office_code = e.office_code
     ) q1
     left outer join
     (select entity_code,
             entity_id
        from at_entity     
     ) q2 on q2.entity_code = q1.parent_code;

create or replace public synonym cwms_v_entity for av_entity;

