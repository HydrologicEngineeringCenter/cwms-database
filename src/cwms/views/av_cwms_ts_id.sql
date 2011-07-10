--
-- AV_CWMS_TS_ID    (View)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Synonym)
--

CREATE OR REPLACE FORCE VIEW av_cwms_ts_id
(
    db_office_id,
    cwms_ts_id,
    unit_id,
    abstract_param_id,
    base_location_id,
    sub_location_id,
    location_id,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    interval_id,
    duration_id,
    version_id,
    interval,
    interval_utc_offset,
    bas_loc_active_flag,
    loc_active_flag,
    ts_active_flag,
    net_ts_active_flag,
    version_flag,
    ts_code,
    db_office_code,
    base_location_code,
    location_code,
    parameter_code
)
AS
    SELECT    db_office_id, cwms_ts_id, unit_id, abstract_param_id,
                base_location_id, sub_location_id, location_id, base_parameter_id,
                sub_parameter_id, parameter_id, parameter_type_id, interval_id,
                duration_id, version_id, interval, interval_utc_offset,base_loc_active_flag,
                loc_active_flag, ts_active_flag, net_ts_active_flag, version_flag,
                ts_code, db_office_code, base_location_code, location_code,
                parameter_code
      FROM    at_cwms_ts_id
/