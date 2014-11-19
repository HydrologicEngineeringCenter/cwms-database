create type loc_alias_type
/**
 * Holds basic information about a location alias.  This information doesn't
 * contain any context for the alias.
 *
 * @see type_loc_alias_array
 * @see type loc_alias_type2
 * @see type loc_alias_type3
 *
 * @member location_id  the location identifier
 * @member loc_alias_id the alias for the location
 */
AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_alias_id   VARCHAR2 (128)
);
/


create or replace public synonym cwms_t_loc_alias for loc_alias_type;

