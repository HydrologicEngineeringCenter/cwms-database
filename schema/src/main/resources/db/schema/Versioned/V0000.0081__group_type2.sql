create type group_type2
/**
 * Holds detailed information about location groups.
 *
 * @see type group_type
 * @see type group_array2
 *
 * @member group_id          the location group identifier
 * @member group_desc        a description of the location group
 * @member shared_alias_id   a location alias shared by all members of the
 *         location group
 * @member shared_loc_ref_id the location identifier for a referenced location
 *         shared by all members of the location group
 */
AS OBJECT (
   GROUP_ID          VARCHAR2 (32),
   group_desc        varchar2 (128),
   shared_alias_id   VARCHAR2 (128),
   shared_loc_ref_id VARCHAR2 (49)
);
/


create or replace public synonym cwms_t_group2 for group_type2;

