create type screen_crit_type
/* (non-javadoc)
 * [description needed]
 *
 * @member season_start_day         [description needed]
 * @member season_start_month       [description needed]
 * @member range_reject_lo          [description needed]
 * @member range_reject_hi          [description needed]
 * @member range_question_lo        [description needed]
 * @member range_question_hi        [description needed]
 * @member rate_change_reject_rise  [description needed]
 * @member rate_change_reject_fall  [description needed]
 * @member rate_change_quest_rise   [description needed]
 * @member rate_change_quest_fall   [description needed]
 * @member const_reject_duration_id [description needed]
 * @member const_reject_min         [description needed]
 * @member const_reject_tolerance   [description needed]
 * @member const_reject_n_miss      [description needed]
 * @member const_quest_duration_id  [description needed]
 * @member const_quest_min          [description needed]
 * @member const_quest_tolerance    [description needed]
 * @member const_quest_n_miss       [description needed]
 * @member estimate_expression      [description needed]
 * @member dur_mag_array            [description needed]
 *
 * @see type screen_crit_array
 */
AS OBJECT (
   season_start_day           NUMBER,
   season_start_month         NUMBER,
   range_reject_lo            NUMBER,
   range_reject_hi            NUMBER,
   range_question_lo          NUMBER,
   range_question_hi          NUMBER,
   rate_change_reject_rise    NUMBER,
   rate_change_reject_fall    NUMBER,
   rate_change_quest_rise     NUMBER,
   rate_change_quest_fall     NUMBER,
   const_reject_duration_id   VARCHAR2 (16),
   const_reject_min           NUMBER,
   const_reject_tolerance     NUMBER,
   const_reject_n_miss        NUMBER,
   const_quest_duration_id    VARCHAR2 (16),
   const_quest_min            NUMBER,
   const_quest_tolerance      NUMBER,
   const_quest_n_miss         NUMBER,
   estimate_expression        VARCHAR2 (32 BYTE),
   dur_mag_array              screen_dur_mag_array
);
/


create or replace public synonym cwms_t_screen_crit for screen_crit_type;

