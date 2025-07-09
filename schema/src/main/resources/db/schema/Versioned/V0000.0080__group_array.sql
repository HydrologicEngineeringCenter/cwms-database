create type group_array
/**
 * Holds basic information about a collection of location groups
 *
 * @see type group_type
 * @see type group_array2
 * @see cwms_loc.assign_loc_grps_cat
 */
IS TABLE OF group_type;
/


create or replace public synonym cwms_t_group_array for group_array;

