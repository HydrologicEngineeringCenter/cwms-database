create or replace type screen_assign_t
/* (non-javadoc)
 * [description needed]
 *
 * @see type screen_assign_array
 *
 * @member cwms_ts_id      [description needed]
 * @member active_flag     [description needed]
 * @member resultant_ts_id [description needed]
 */
AS OBJECT (
   cwms_ts_id        VARCHAR2(191),
   active_flag       VARCHAR2 (1),
   resultant_ts_id   VARCHAR2(191)
);
/


create or replace public synonym cwms_t_screen_assign for screen_assign_t;

