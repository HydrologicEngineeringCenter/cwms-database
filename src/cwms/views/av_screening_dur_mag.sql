insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_SCREENING_DUR_MAG', null,
'
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
');
CREATE OR REPLACE VIEW av_screening_dur_mag
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
    dur_mag_duration_id,
    reject_lo,
    reject_hi,
    question_lo,
    question_hi
)
AS
    SELECT    atsdm.screening_code, co.office_id db_office_id,
                atsi.screening_id, atsi.screening_id_desc, cbp.base_parameter_id,
                atp.sub_parameter_id,
                cbp.base_parameter_id || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id)) || atp.sub_parameter_id parameter_id,
                cpt.parameter_type_id, cd.duration_id,
                MOD (atsdm.season_start_date, 30) season_start_day,
                (atsdm.season_start_date - MOD (atsdm.season_start_date, 30)) / 30 + 1 season_start_month,
                adu.unit_system, cuc.to_unit_id unit_id,
                cd2.duration_id dur_mag_duration_id,
                atsdm.reject_lo * cuc.factor + cuc.offset reject_lo,
                atsdm.reject_hi * cuc.factor + cuc.offset reject_hi,
                atsdm.question_lo * cuc.factor + cuc.offset question_lo,
                atsdm.question_hi * cuc.factor + cuc.offset question_hi
      FROM    at_screening_id atsi,
                cwms_office co,
                at_parameter atp,
                cwms_base_parameter cbp,
                cwms_parameter_type cpt,
                cwms_duration cd,
                cwms_duration cd2,
                at_display_units adu,
                cwms_unit_conversion cuc,
                at_screening_dur_mag atsdm
     WHERE         co.office_code = atsi.db_office_code
                AND cbp.base_parameter_code = atsi.base_parameter_code
                AND atp.parameter_code = atsi.parameter_code
                AND atsi.parameter_type_code = cpt.parameter_type_code(+)
                AND atsi.duration_code = cd.duration_code(+)
                AND atsdm.duration_code = cd2.duration_code
                AND atsi.screening_code = atsdm.screening_code
                AND atsi.db_office_code = adu.db_office_code
                AND cbp.unit_code = cuc.from_unit_code
                AND adu.display_unit_code = cuc.to_unit_code
                AND atsi.parameter_code = adu.parameter_code
/