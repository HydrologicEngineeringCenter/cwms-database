create type entity_tab_t
/**
 * Holds a collection of entities
 */
as table of entity_t;
/

create or replace public synonym cwms_t_entity_tab for entity_tab_t;
