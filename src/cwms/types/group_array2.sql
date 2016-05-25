create type group_array2
/**
 * Holds basic information about a collection of location groups
 *
 * @see type group_type2
 * @see type group_array
 * @see cwms_loc.assign_loc_grps_cat2
 */
IS TABLE OF group_type2;
/


create or replace public synonym cwms_t_group2_array for group_array2;

