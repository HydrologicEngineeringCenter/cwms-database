create type tr_template_set_type
/* (non-javadoc)
 * [description needed]
 *
 * @see type tr_template_set_array
 * @see type char_183_array_type
 *
 * @member description           [description needed]
 * @member store_dep_flag        [description needed]
 * @member unit_system           [description needed]
 * @member transform_id          [description needed]
 * @member lookup_agency         [description needed]
 * @member lookup_rating_version [description needed]
 * @member scaling_arg_a         [description needed]
 * @member scaling_arg_b         [description needed]
 * @member scaling_arg_c         [description needed]
 * @member array_of_masks        [description needed]
 */
AS OBJECT (
   description             VARCHAR2 (132),
   store_dep_flag          VARCHAR2 (1),
   unit_system             VARCHAR2 (2),
   transform_id            VARCHAR2 (32),
   lookup_agency           VARCHAR2 (32),
   lookup_rating_version   VARCHAR2 (32),
   scaling_arg_a           NUMBER,
   scaling_arg_b           NUMBER,
   scaling_arg_c           NUMBER,
   array_of_masks          char_183_array_type
);
/


create or replace public synonym cwms_t_tr_template_set for tr_template_set_type;

