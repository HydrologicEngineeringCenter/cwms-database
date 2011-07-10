CREATE OR REPLACE VIEW av_screened_ts_ids
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