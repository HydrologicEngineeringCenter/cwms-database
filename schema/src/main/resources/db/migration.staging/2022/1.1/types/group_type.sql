create type group_type
/**
 * Holds basic information about location groups
 *
 * @see type group_type2
 * @see type group_array
 *
 * @member group_id   the location group identifier
 * @member group_desc a description of the location group
 */
AS OBJECT (
   GROUP_ID     VARCHAR2 (32),
   group_desc   VARCHAR2 (128)
);
/


create or replace public synonym cwms_t_group for group_type;

