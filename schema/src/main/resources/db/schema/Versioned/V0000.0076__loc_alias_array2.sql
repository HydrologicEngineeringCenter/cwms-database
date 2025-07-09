create type loc_alias_array2
/**
 * Holds intermediate information about a collection of location aliases.  This
 * information doesn't contain any context for the aliases.
 *
 * @see type_loc_alias_type2
 * @see type loc_alias_array
 * @see type loc_alias_array3
 * @see cwms_loc.assign_loc_groups2
 */
IS TABLE OF loc_alias_type2;
/


create or replace public synonym cwms_t_loc_alias2_array for loc_alias_array2;

