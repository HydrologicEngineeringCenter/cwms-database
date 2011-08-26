insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_SCREENING_ASSIGNMENTS', null,
'
/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field     screening_code     [description needed]
 * @field     ts_code            [description needed]
 * @field     base_location_code [description needed]
 * @field     location_code      [description needed]
 * @field     db_office_id       [description needed]
 * @field     screening_id       [description needed]
 * @field     active_flag        [description needed]
 * @field     resultant_ts_code  [description needed]
 * @field     screening_id_desc  [description needed]
 * @field     cwms_ts_id         [description needed]
 * @field     base_location_id   [description needed]
 * @field     sub_location_id    [description needed]
 * @field     location_id        [description needed]
 * @field     base_parameter_id  [description needed]
 * @field     sub_parameter_id   [description needed]
 * @field     parameter_id       [description needed]
 * @field     parameter_type_id  [description needed]
 * @field     duration_id        [description needed]
 */
');
CREATE OR REPLACE VIEW av_screening_assignments
(
    screening_code,
    ts_code,
    base_location_code,
    location_code,
    db_office_id,
    screening_id,
    active_flag,
    resultant_ts_code,
    screening_id_desc,
    cwms_ts_id,
    base_location_id,
    sub_location_id,
    location_id,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    duration_id
)
AS
    SELECT    atsi.screening_code, ats.ts_code, mcti.base_location_code,
                mcti.location_code, mcti.db_office_id, atsi.screening_id,
                ats.active_flag, ats.resultant_ts_code, atsi.screening_id_desc,
                mcti.cwms_ts_id, mcti.base_location_id, mcti.sub_location_id,
                mcti.location_id, mcti.base_parameter_id, mcti.sub_parameter_id,
                mcti.parameter_id, mcti.parameter_type_id, mcti.duration_id
      FROM    mv_cwms_ts_id mcti, at_screening_id atsi, at_screening ats
     WHERE    ats.screening_code = atsi.screening_code
                AND ats.ts_code = mcti.ts_code
/