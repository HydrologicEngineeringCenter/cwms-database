create type loc_alias_type3
/**
 * Holds detailed information about a location alias.  This information doesn't
 * contain any context for the alias.
 *
 * @see type_loc_alias_array3
 * @see type loc_alias_type2
 * @see type loc_alias_type3
 *
 * @member location_id   the location identifier
 * @member loc_attribute a numeric attribute associated with the location and alias.
 *         This can be used for sorting locations within a location group or other
 *         user-defined purposes.
 * @member loc_alias_id  the alias for the location
 * @member loc_ref_id    the location identifier of a referenced location
 */
AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_attribute  NUMBER,
   loc_alias_id   VARCHAR2 (128),
   loc_ref_id     VARCHAR2 (49)
);
/


create or replace public synonym cwms_t_loc_alias3 for loc_alias_type3;

