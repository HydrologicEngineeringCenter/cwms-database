/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field screening_code      [description needed]
 * @field db_office_id        [description needed]
 * @field screening_id        [description needed]
 * @field screening_id_desc   [description needed]
 * @field base_parameter_id   [description needed]
 * @field sub_parameter_id    [description needed]
 * @field parameter_id        [description needed]
 * @field parameter_type_id   [description needed]
 * @field duration_id         [description needed]
 * @field season_start_day    [description needed]
 * @field season_start_month  [description needed]
 * @field unit_system         [description needed]
 * @field unit_id             [description needed]
 * @field dur_mag_duration_id [description needed]
 * @field reject_lo           [description needed]
 * @field reject_hi           [description needed]
 * @field question_lo         [description needed]
 * @field question_hi         [description needed]
 */
CREATE OR REPLACE FORCE VIEW AV_SCREENING_DUR_MAG
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
   DUR_MAG_DURATION_ID,
   REJECT_LO,
   REJECT_HI,
   QUESTION_LO,
   QUESTION_HI
)
AS
   SELECT atsdm.screening_code,
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
          MOD (atsdm.season_start_date, 30) season_start_day,
              (atsdm.season_start_date - MOD (atsdm.season_start_date, 30))
            / 30
          + 1
             season_start_month,
          bpdu.unit_system,
          cuc.to_unit_id unit_id,
          cd2.duration_id dur_mag_duration_id,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(atsdm.reject_lo)), atsdm.reject_lo) reject_lo,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(atsdm.reject_hi)), atsdm.reject_hi) reject_hi,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(atsdm.question_lo)), atsdm.question_lo) question_lo,
          nvl(cwms_util.eval_rpn_expression(cuc.function, double_tab_t(atsdm.question_hi)), atsdm.question_hi) question_hi
     FROM at_screening_id atsi,
          cwms_office co,
          at_parameter atp,
          cwms_base_parameter cbp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          cwms_duration cd2,
          av_base_parm_display_units bpdu,
          cwms_unit_conversion cuc,
          at_screening_dur_mag atsdm
    WHERE     co.office_code = atsi.db_office_code
          AND cbp.base_parameter_code = atsi.base_parameter_code
          AND atp.parameter_code = atsi.parameter_code
          AND atsi.parameter_type_code = cpt.parameter_type_code(+)
          AND atsi.duration_code = cd.duration_code(+)
          AND atsdm.duration_code = cd2.duration_code
          AND atsi.screening_code = atsdm.screening_code
          AND cbp.unit_code = cuc.from_unit_code
          AND bpdu.unit_code = cuc.to_unit_code
          AND atsi.base_parameter_code = bpdu.base_parameter_code;
/
