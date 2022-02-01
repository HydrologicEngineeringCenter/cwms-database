create type screen_dur_mag_type
/* (non-javadoc)
 * [description needed]
 *
 * @member duration_id  [description needed]
 * @member reject_lo    [description needed]
 * @member reject_hi    [description needed]
 * @member question_lo  [description needed]
 * @member question_hi  [description needed]
 *
 * @see type screen_dur_mag_array
 */
AS OBJECT (
   duration_id   VARCHAR2 (16),
   reject_lo     NUMBER,
   reject_hi     NUMBER,
   question_lo   NUMBER,
   question_hi   NUMBER
);
/


create or replace public synonym cwms_t_screen_dur_mag for screen_dur_mag_type;

