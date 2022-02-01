create type group_array3
/**
 * Holds basic information about a collection of location groups
 *
 * @see type group_type3
 * @see type group_array
 * @see cwms_loc.assign_loc_grps_cat3
 */
IS TABLE OF group_type3;
/


create or replace public synonym cwms_t_group3_array for group_array3;

