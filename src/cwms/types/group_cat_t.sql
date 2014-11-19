create type group_cat_t
/**
 * Holds the name of a location group within a specific location category
 *
 * @see group_cat_tab_t
 *
 * @member loc_category_id the location category identifier (parent of location group)
 * @member loc_group_id    the location group identifier (child of location category)
 */
AS OBJECT (
   loc_category_id   VARCHAR2 (32),
   loc_group_id      VARCHAR2 (32)
);
/


create or replace public synonym cwms_t_group_cat for group_cat_t;

