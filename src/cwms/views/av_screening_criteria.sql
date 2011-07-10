CREATE OR REPLACE FORCE VIEW av_screening_criteria
(
    screening_code,
    db_office_id,
    screening_id,
    screening_id_desc,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    duration_id,
    season_start_day,
    season_start_month,
    unit_system,
    unit_id,
    range_reject_lo,
    range_reject_hi,
    range_question_lo,
    range_question_hi,
    rate_change_reject_rise,
    rate_change_reject_fall,
    rate_change_quest_rise,
    rate_change_quest_fall,
    rate_change_disp_interval,
    const_reject_duration,
    const_reject_min,
    const_reject_tolerance,
    const_reject_n_miss,
    const_quest_duration,
    const_quest_min,
    const_quest_tolerance,
    const_quest_n_miss,
    estimate_expression,
    range_active_flag,
    rate_change_active_flag,
    const_active_flag,
    dur_mag_active_flag,
    rate_change_disp_interval_id
)
AS
    SELECT    atsi.screening_code,
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
                adu.unit_system,
                cuc.to_unit_id unit_id,
                avsc.range_reject_lo * cuc.factor + cuc.offset range_reject_lo,
                avsc.range_reject_hi * cuc.factor + cuc.offset range_reject_hi,
                avsc.range_question_lo * cuc.factor + cuc.offset
                    range_question_lo,
                avsc.range_question_hi * cuc.factor + cuc.offset
                    range_question_hi,
                avsc.rate_change_reject_rise * cuc.factor + cuc.offset
                    rate_change_reject_rise,
                avsc.rate_change_reject_fall * cuc.factor + cuc.offset
                    rate_change_reject_fall,
                avsc.rate_change_quest_rise * cuc.factor + cuc.offset
                    rate_change_quest_rise,
                avsc.rate_change_quest_fall * cuc.factor + cuc.offset
                    rate_change_quest_fall,
                CASE
                    WHEN asctl.rate_change_disp_interval_code IS NULL
                    THEN
                        'Unknown'
                    ELSE
                        (SELECT     interval_id
                            FROM     cwms_interval
                          WHERE     interval_code =
                                         asctl.rate_change_disp_interval_code)
                END
                    rate_change_disp_interval,
                CASE
                    WHEN avsc.const_reject_duration_code IS NULL
                    THEN
                        'Unknown'
                    ELSE
                        (SELECT     duration_id
                            FROM     cwms_duration
                          WHERE     duration_code = avsc.const_reject_duration_code)
                END
                    const_reject_duration,
                avsc.const_reject_min * cuc.factor + cuc.offset const_reject_min,
                avsc.const_reject_tolerance * cuc.factor + cuc.offset
                    const_reject_tolerance,
                avsc.const_reject_n_miss,
                CASE
                    WHEN avsc.const_quest_duration_code IS NULL
                    THEN
                        'Unknown'
                    ELSE
                        (SELECT     duration_id
                            FROM     cwms_duration
                          WHERE     duration_code = avsc.const_quest_duration_code)
                END
                    const_quest_duration,
                avsc.const_quest_min * cuc.factor + cuc.offset const_quest_min,
                avsc.const_quest_tolerance * cuc.factor + cuc.offset
                    const_quest_tolerance,
                avsc.const_quest_n_miss,
                avsc.estimate_expression,
                asctl.range_active_flag,
                asctl.rate_change_active_flag,
                asctl.const_active_flag,
                asctl.dur_mag_active_flag,
                ci.interval_id rate_change_disp_interval_id
      FROM    at_screening_id atsi,
                cwms_office co,
                at_parameter atp,
                cwms_base_parameter cbp,
                cwms_parameter_type cpt,
                cwms_duration cd,
                cwms_interval ci,
                at_display_units adu,
                cwms_unit_conversion cuc,
                at_screening_criteria avsc,
                at_screening_control asctl
     WHERE         co.office_code = atsi.db_office_code
                AND cbp.base_parameter_code = atsi.base_parameter_code
                AND atp.parameter_code = atsi.parameter_code
                AND atsi.parameter_type_code = cpt.parameter_type_code(+)
                AND atsi.duration_code = cd.duration_code(+)
                AND atsi.screening_code = avsc.screening_code(+)
                AND atsi.db_office_code = adu.db_office_code
                AND cbp.unit_code = cuc.from_unit_code
                AND adu.display_unit_code = cuc.to_unit_code
                AND atsi.parameter_code = adu.parameter_code
                AND avsc.screening_code = asctl.screening_code(+)
                AND asctl.rate_change_disp_interval_code = ci.interval_code(+)
/