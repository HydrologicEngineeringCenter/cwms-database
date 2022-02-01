create type loc_alias_array
/**
 * Holds basic information about a collection of location aliases.  This information
 * doesn't contain any context for the aliases.
 *
 * @see type_loc_alias_type
 * @see type loc_alias_array2
 * @see type loc_alias_array3
 * @see cwms_loc.assign_loc_groups
 */
IS TABLE OF loc_alias_type;
/


create or replace public synonym cwms_t_loc_alias_array for loc_alias_array;

