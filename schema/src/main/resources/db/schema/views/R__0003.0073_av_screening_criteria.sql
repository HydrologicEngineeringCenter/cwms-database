/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field screening_code               [description needed]
 * @field db_office_id                 [description needed]
 * @field screening_id                 [description needed]
 * @field screening_id_desc            [description needed]
 * @field base_parameter_id            [description needed]
 * @field sub_parameter_id             [description needed]
 * @field parameter_id                 [description needed]
 * @field parameter_type_id            [description needed]
 * @field duration_id                  [description needed]
 * @field season_start_day             [description needed]
 * @field season_start_month           [description needed]
 * @field unit_system                  [description needed]
 * @field unit_id                      [description needed]
 * @field range_reject_lo              [description needed]
 * @field range_reject_hi              [description needed]
 * @field range_question_lo            [description needed]
 * @field range_question_hi            [description needed]
 * @field rate_change_reject_rise      [description needed]
 * @field rate_change_reject_fall      [description needed]
 * @field rate_change_quest_rise       [description needed]
 * @field rate_change_quest_fall       [description needed]
 * @field rate_change_disp_interval    [description needed]
 * @field const_reject_duration        [description needed]
 * @field const_reject_min             [description needed]
 * @field const_reject_tolerance       [description needed]
 * @field const_reject_n_miss          [description needed]
 * @field const_quest_duration         [description needed]
 * @field const_quest_min              [description needed]
 * @field const_quest_tolerance        [description needed]
 * @field const_quest_n_miss           [description needed]
 * @field estimate_expression          [description needed]
 * @field range_active_flag            [description needed]
 * @field rate_change_active_flag      [description needed]
 * @field const_active_flag            [description needed]
 * @field dur_mag_active_flag          [description needed]
 * @field rate_change_disp_interval_id [description needed]
 */
CREATE OR REPLACE FORCE VIEW AV_SCREENING_CRITERIA
(
   SCREENING_CODE,
   DB_OFFICE_ID,
   SCREENING_ID,
   SCREENING_ID_DESC,
   BASE_PARAMETER_ID,
   SUB_PARAMETER_ID,
   PARAMETER_ID,
   PARAMETER_TYPE_ID,
   DURATION_ID,
   SEASON_START_DAY,
   SEASON_START_MONTH,
   UNIT_SYSTEM,
   UNIT_ID,
   RANGE_REJECT_LO,
   RANGE_REJECT_HI,
   RANGE_QUESTION_LO,
   RANGE_QUESTION_HI,
   RATE_CHANGE_REJECT_RISE,
   RATE_CHANGE_REJECT_FALL,
   RATE_CHANGE_QUEST_RISE,
   RATE_CHANGE_QUEST_FALL,
   RATE_CHANGE_DISP_INTERVAL,
   CONST_REJECT_DURATION,
   CONST_REJECT_MIN,
   CONST_REJECT_TOLERANCE,
   CONST_REJECT_N_MISS,
   CONST_QUEST_DURATION,
   CONST_QUEST_MIN,
   CONST_QUEST_TOLERANCE,
   CONST_QUEST_N_MISS,
   ESTIMATE_EXPRESSION,
   RANGE_ACTIVE_FLAG,
   RATE_CHANGE_ACTIVE_FLAG,
   CONST_ACTIVE_FLAG,
   DUR_MAG_ACTIVE_FLAG,
   RATE_CHANGE_DISP_INTERVAL_ID
)
AS
   SELECT atsi.screening_code,
          co.office_id db_office_id,
          atsi.screening_id,
          atsi.screening_id_desc,
          cbp.base_parameter_id,
          atp.sub_parameter_id,
             cbp.base_parameter_id
          || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
          || atp.sub_parameter_id
             parameter_id,
          cpt.parameter_type_id,
          cd.duration_id,
          MOD (avsc.season_start_date, 30) season_start_day,
            (avsc.season_start_date - MOD (avsc.season_start_date, 30)) / 30
          + 1
             season_start_month,
          bpdu.unit_system,
          cuc.to_unit_id unit_id,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.range_reject_lo)), avsc.range_reject_lo) range_reject_lo,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.range_reject_hi)), avsc.range_reject_hi) range_reject_hi,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.range_question_lo)), avsc.range_question_lo) range_question_lo,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.range_question_hi)), avsc.range_question_hi) range_question_hi,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.rate_change_reject_rise)), avsc.rate_change_reject_rise)
             rate_change_reject_rise,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.rate_change_reject_fall)), avsc.rate_change_reject_fall)
             rate_change_reject_fall,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.rate_change_quest_rise)), avsc.rate_change_quest_rise)
             rate_change_quest_rise,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.rate_change_quest_fall)), avsc.rate_change_quest_fall)
             rate_change_quest_fall,
          CASE
             WHEN asctl.rate_change_disp_interval_code IS NULL
             THEN
                'Unknown'
             ELSE
                (SELECT interval_id
                   FROM cwms_interval
                  WHERE interval_code = asctl.rate_change_disp_interval_code)
          END
             rate_change_disp_interval,
          CASE
             WHEN avsc.const_reject_duration_code IS NULL
             THEN
                'Unknown'
             ELSE
                (SELECT duration_id
                   FROM cwms_duration
                  WHERE duration_code = avsc.const_reject_duration_code)
          END
             const_reject_duration,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.const_reject_min)), avsc.const_reject_min) const_reject_min,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.const_reject_tolerance)), avsc.const_reject_tolerance)
             const_reject_tolerance,
          avsc.const_reject_n_miss,
          CASE
             WHEN avsc.const_quest_duration_code IS NULL
             THEN
                'Unknown'
             ELSE
                (SELECT duration_id
                   FROM cwms_duration
                  WHERE duration_code = avsc.const_quest_duration_code)
          END
             const_quest_duration,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.const_quest_min)), avsc.const_quest_min) const_quest_min,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(avsc.const_quest_tolerance)), avsc.const_quest_tolerance)
             const_quest_tolerance,
          avsc.const_quest_n_miss,
          avsc.estimate_expression,
          asctl.range_active_flag,
          asctl.rate_change_active_flag,
          asctl.const_active_flag,
          asctl.dur_mag_active_flag,
          ci.interval_id rate_change_disp_interval_id
     FROM at_screening_id atsi,
          cwms_office co,
          at_parameter atp,
          cwms_base_parameter cbp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          cwms_interval ci,
          av_base_parm_display_units bpdu,
          cwms_unit_conversion cuc,
          at_screening_criteria avsc,
          at_screening_control asctl
    WHERE     co.office_code = atsi.db_office_code
          AND cbp.base_parameter_code = atsi.base_parameter_code
          AND atp.parameter_code = atsi.parameter_code
          AND atsi.parameter_type_code = cpt.parameter_type_code(+)
          AND atsi.duration_code = cd.duration_code(+)
          AND atsi.screening_code = avsc.screening_code(+)
          AND cbp.unit_code = cuc.from_unit_code
          AND bpdu.unit_code = cuc.to_unit_code
          AND atsi.base_parameter_code = bpdu.base_parameter_code
          AND avsc.screening_code = asctl.screening_code(+)
          AND asctl.rate_change_disp_interval_code = ci.interval_code(+);
/
