--
-- AV_ACTIVE_FLAG  (View)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--   AT_DATA_STREAM_ID (Table)
--   AT_SHEF_DECODE (Table)
--

CREATE OR REPLACE FORCE VIEW av_active_flag
(
    data_stream_id,
    shef_spec,
    db_office_code,
    db_office_id,
    ts_code,
    cwms_ts_id,
    base_loc_active_flag,
    loc_active_flag,
    ts_active_flag,
    ds_active_flag,
    net_active_flag
)
AS
    SELECT    c.data_stream_id,
                UPPER (b.shef_loc_id || SUBSTR ('.', 1, LENGTH (b.shef_loc_id)) || b.shef_pe_code || SUBSTR ('.', 1, LENGTH (b.shef_loc_id)) || b.shef_tse_code || SUBSTR ('.', 1, LENGTH (b.shef_loc_id)) || b.shef_duration_numeric) shef_spec,
                a.db_office_code, a.db_office_id, a.ts_code, a.cwms_ts_id,
                a.base_loc_active_flag, a.loc_active_flag, a.ts_active_flag,
                CASE WHEN c.active_flag IS NULL THEN 'N/A' ELSE c.active_flag END ds_active_flag,
                CASE WHEN c.active_flag IS NULL THEN a.net_ts_active_flag WHEN a.net_ts_active_flag = 'T' AND c.active_flag = 'T' THEN 'T' ELSE 'F' END net_active_flag
      FROM    at_cwms_ts_id a, at_shef_decode b, at_data_stream_id c
     WHERE    a.ts_code = b.ts_code(+)
                AND b.data_stream_code = c.data_stream_code(+)
/