create type group_cat_tab_t
/**
 * Holds a collection of location group names within specific location categories
 *
 * @see group_cat_t
 * @see cwms_loc.num_group_assigned_to_shef
 */
IS TABLE OF group_cat_t;
/


create or replace public synonym cwms_t_group_cat_tab for group_cat_tab_t;

