--
-- ZAV_CWMS_TS_ID  (View)
--
--  Dependencies:
--   CWMS_INTERVAL (Table)
--   CWMS_OFFICE (Table)
--   CWMS_PARAMETER_TYPE (Table)
--   CWMS_UNIT (Table)
--   CWMS_ABSTRACT_PARAMETER (Table)
--   CWMS_BASE_PARAMETER (Table)
--   CWMS_DURATION (Table)
--   AT_BASE_LOCATION (Table)
--   AT_CWMS_TS_SPEC (Table)
--   AT_PARAMETER (Table)
--   AT_PHYSICAL_LOCATION (Table)
--

CREATE OR REPLACE FORCE VIEW zav_cwms_ts_id
(
    db_office_code,
    base_location_code,
    base_loc_active_flag,
    location_code,
    loc_active_flag,
    parameter_code,
    ts_code,
    ts_active_flag,
    net_ts_active_flag,
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
    version_flag
)
AS
    SELECT    abl.db_office_code, base_location_code,
                abl.active_flag base_loc_active_flag, location_code,
                l.active_flag loc_active_flag, parameter_code, s.ts_code,
                s.active_flag ts_active_flag,
                CASE WHEN abl.active_flag = 'T' AND l.active_flag = 'T' AND s.active_flag = 'T' THEN 'T' ELSE 'F' END net_ts_active_flag,
                o.office_id db_office_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (l.sub_location_id)) || l.sub_location_id || '.' || base_parameter_id || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id)) || ap.sub_parameter_id || '.' || parameter_type_id || '.' || interval_id || '.' || duration_id || '.' || version cwms_ts_id,
                u.unit_id, cap.abstract_param_id, abl.base_location_id,
                l.sub_location_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (l.sub_location_id)) || l.sub_location_id location_id,
                base_parameter_id, ap.sub_parameter_id,
                base_parameter_id || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id)) || ap.sub_parameter_id parameter_id,
                parameter_type_id, interval_id, duration_id, version version_id,
                i.interval, s.interval_utc_offset, s.version_flag
      FROM    at_cwms_ts_spec s
                JOIN at_physical_location l
                    USING (location_code)
                JOIN at_base_location abl
                    USING (base_location_code)
                JOIN cwms_office o
                    ON (abl.db_office_code = o.office_code)
                JOIN at_parameter ap
                    USING (parameter_code)
                JOIN cwms_base_parameter p
                    USING (base_parameter_code)
                JOIN cwms_unit u
                    USING (unit_code)
                JOIN cwms_abstract_parameter cap
                    ON (cap.abstract_param_code = u.abstract_param_code)
                JOIN cwms_parameter_type t
                    USING (parameter_type_code)
                JOIN cwms_interval i
                    USING (interval_code)
                JOIN cwms_duration d
                    USING (duration_code)
     WHERE    s.delete_date IS NULL
/