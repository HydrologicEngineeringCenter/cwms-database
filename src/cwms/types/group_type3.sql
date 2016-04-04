create type group_type3
/**
 * Holds detailed information about location groups.
 *
 * @see type group_type
 * @see type group_array2
 *
 * @member group_id          the location group identifier
 * @member group_desc        a description of the location group
 * @member group_attribute   a number that can be used for sorting, etc...
 * @member shared_alias_id   a location alias shared by all members of the
 *         location group
 * @member shared_loc_ref_id the location identifier for a referenced location
 *         shared by all members of the location group
 */
AS OBJECT (
   GROUP_ID          VARCHAR2 (32),
   group_desc        VARCHAR2 (128),
   group_attribute   NUMBER,
   shared_alias_id   VARCHAR2 (128),
   shared_loc_ref_id VARCHAR2 (49)
);
/


create or replace public synonym cwms_t_group3 for group_type3;

