create type entity_t
/**
 * Object representing a single entity in the database
 *
 * @member office_id   The office that owns the entity
 * @member category_id Category describing the type of entity
 * @member entity_id   The text identifier of the entity
 * @member entity_name The name of the entity
 */
as object (
   office_id   varchar2(16),
   category_id varchar2(3),
   entity_id   varchar2(32),
   entity_name varchar2(128)
);
/

create or replace public synonym cwms_t_entity for entity_t;
