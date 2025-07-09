create type screening_control_t
/* (non-javadoc)
 * [description needed]
 *
 * @see cwms_vt.store_screening_criteria
 *
 * @member range_active_flag       [description needed]
 * @member rate_change_active_flag [description needed]
 * @member const_active_flag       [description needed]
 * @member dur_mag_active_flag     [description needed]
 */
AS OBJECT (
   range_active_flag         VARCHAR2 (1),
   rate_change_active_flag   VARCHAR2 (1),
   const_active_flag         VARCHAR2 (1),
   dur_mag_active_flag       VARCHAR2 (1)
);
/


create or replace public synonym cwms_t_screening_control for screening_control_t;

