/* Formatted on 12/29/2011 8:46:31 AM (QP5 v5.185.11230.41888) */
--
-- AV_SHEF_DECODE_SPEC    (View)
--
--  Dependencies:
--   AT_LOC_CATEGORY (Table)
--   AT_LOC_GROUP (Table)
--   AT_LOC_GROUP_ASSIGNMENT (Table)
--   AT_CWMS_TS_ID (Table)
--   AT_CWMS_TS_SPEC (Table)
--   AT_DATA_FEED_ID (Table)
--   AT_DATA_STREAM_ID (Table)
--   CWMS_OFFICE (Table)
--   CWMS_SHEF_TIME_ZONE (Table)
--   CWMS_UNIT (Table)
--   CWMS_UTIL (Package)
--   AT_SHEF_DECODE (Table)
--   AT_SHEF_IGNORE (Table)
--

INSERT INTO at_clob
     VALUES (cwms_seq.NEXTVAL,
             53,
             '/VIEWDOCS/AV_SHEF_DECODE_SPEC',
             NULL,
             '
/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field ts_code               [description needed]
 * @field cwms_ts_id            [description needed]
 * @field db_office_id          [description needed]
 * @field data_stream_id        [description needed]
 * @field stream_db_office_id   [description needed]
 * @field data_feed_id          [description needed]
 * @field feed_db_office_id     [description needed]
 * @field data_feed_prefix      [description needed]
 * @field loc_group_id          [description needed]
 * @field loc_category_id       [description needed]
 * @field loc_alias_id          [description needed]
 * @field shef_loc_id           [description needed]
 * @field shef_pe_code          [description needed]
 * @field shef_tse_code         [description needed]
 * @field shef_duration_code    [description needed]
 * @field shef_duration_numeric [description needed]
 * @field shef_time_zone_id     [description needed]
 * @field dl_time               [description needed]
 * @field unit_id               [description needed]
 * @field unit_system           [description needed]
 * @field interval_utc_offset   [description needed]
 * @field interval_forward      [description needed]
 * @field interval_backward     [description needed]
 * @field ts_active_flag        [description needed]
 * @field net_ts_active_flag    [description needed]
 * @field ignore_shef_spec      [description needed]
 * @field shef_spec             [description needed]
 * @field location_id           [description needed]
 * @field parameter_id          [description needed]
 * @field parameter_type_id     [description needed]
 * @field interval_id           [description needed]
 * @field duration_id           [description needed]
 * @field version_id            [description needed]
 * @field data_stream_code      [description needed]
 * @field shef_crit_line        [description needed]
 */
');

CREATE OR REPLACE FORCE VIEW CWMS_20.AV_SHEF_DECODE_SPEC
(
   TS_CODE,
   CWMS_TS_ID,
   DB_OFFICE_ID,
   DATA_STREAM_ID,
   STREAM_DB_OFFICE_ID,
   DATA_FEED_ID,
   FEED_DB_OFFICE_ID,
   DATA_FEED_PREFIX,
   LOC_GROUP_ID,
   LOC_CATEGORY_ID,
   LOC_ALIAS_ID,
   SHEF_LOC_ID,
   SHEF_PE_CODE,
   SHEF_TSE_CODE,
   SHEF_DURATION_CODE,
   SHEF_DURATION_NUMERIC,
   SHEF_TIME_ZONE_ID,
   DL_TIME,
   UNIT_ID,
   UNIT_SYSTEM,
   INTERVAL_UTC_OFFSET,
   INTERVAL_FORWARD,
   INTERVAL_BACKWARD,
   TS_ACTIVE_FLAG,
   NET_TS_ACTIVE_FLAG,
   IGNORE_SHEF_SPEC,
   SHEF_SPEC,
   LOCATION_ID,
   PARAMETER_ID,
   PARAMETER_TYPE_ID,
   INTERVAL_ID,
   DURATION_ID,
   VERSION_ID,
   DATA_STREAM_CODE,
   SHEF_CRIT_LINE
)
AS
   SELECT a.ts_code,
          a.cwms_ts_id,
          a.db_office_id,
          a.data_stream_id,
          k.office_id stream_db_office_id,
          j.data_feed_id,
          l.office_id feed_db_office_id,
          j.data_feed_prefix,
          a.loc_group_id,
          a.loc_category_id,
          a.loc_alias_id,
          a.shef_loc_id,
          a.shef_pe_code,
          a.shef_tse_code,
          a.shef_duration_code,
          a.shef_duration_numeric,
          a.shef_time_zone_id,
          a.dl_time,
          a.unit_id,
          a.unit_system,
          a.interval_utc_offset,
          a.interval_forward,
          a.interval_backward,
          a.ts_active_flag,
          a.net_ts_active_flag,
          a.ignore_shef_spec,
          TRIM (j.data_feed_prefix) || a.shef_spec shef_spec,
          a.location_id,
          a.parameter_id,
          a.parameter_type_id,
          a.interval_id,
          a.duration_id,
          a.version_id,
          a.data_stream_code,
             CASE WHEN a.ignore_shef_spec = 'T' THEN '//' ELSE NULL END
          || TRIM (j.data_feed_prefix)
          || a.shef_spec
          || '='
          || a.cwms_ts_id
          || a.shef_unit_string
          || a.shef_tz_string
          || a.shef_dltime_string
          || a.int_for_back_string
             shef_crit_line
     FROM (SELECT ts_code,
                  b.cwms_ts_id,
                  b.db_office_id,
                  c.data_stream_id,
                  e.loc_group_id,
                  f.loc_category_id,
                  CASE
                     WHEN d.loc_alias_id IS NULL THEN b.location_id
                     ELSE d.loc_alias_id
                  END
                     loc_alias_id,
                  a.shef_loc_id,
                  a.shef_pe_code,
                  a.shef_tse_code,
                  a.shef_duration_code,
                  a.shef_duration_numeric,
                  g.shef_time_zone_id,
                  a.dl_time,
                  i.unit_id,
                  i.unit_system,
                  CASE
                     WHEN h.interval_utc_offset = -2147483648 THEN NULL
                     WHEN h.interval_utc_offset = 2147483647 THEN NULL
                     ELSE TO_CHAR (h.interval_utc_offset, '9999999999')
                  END
                     interval_utc_offset,
                  CASE
                     WHEN h.interval_utc_offset >= 0
                     THEN
                           CASE
                              WHEN h.interval_utc_offset != 2147483647
                              THEN
                                    ';IntervalOffset='
                                 || cwms_util.get_interval_string (
                                       h.interval_utc_offset)
                           END
                        || CASE
                              WHEN     h.interval_forward IS NOT NULL
                                   AND h.interval_backward IS NOT NULL
                              THEN
                                    ';IntervalForward='
                                 || cwms_util.get_interval_string (
                                       h.interval_forward)
                                 || ';IntervalBackward='
                                 || cwms_util.get_interval_string (
                                       h.interval_backward)
                           END
                  END
                     int_for_back_string,
                  CASE
                     WHEN a.shef_unit_code IS NOT NULL
                     THEN
                        ';Units=' || i.unit_id
                  END
                     shef_unit_string,
                  CASE
                     WHEN shef_time_zone_code IS NOT NULL
                     THEN
                        ';TZ=' || shef_time_zone_id
                  END
                     shef_tz_string,
                     ';DLTime='
                  || CASE WHEN a.dl_time = 'T' THEN 'true' ELSE 'false' END
                     shef_dltime_string,
                  h.interval_forward,
                  h.interval_backward,
                  b.ts_active_flag,
                  b.net_ts_active_flag,
                  a.ignore_shef_spec,
                  b.location_id,
                  b.parameter_id,
                  b.parameter_type_id,
                  b.interval_id,
                  b.duration_id,
                  b.version_id,
                  data_stream_code,
                  a.data_feed_code,
                  c.db_office_code,
                  shef_time_zone_code,
                     loc_alias_id
                  || '.'
                  || shef_pe_code
                  || '.'
                  || shef_tse_code
                  || '.'
                  || shef_duration_numeric
                     shef_spec
             FROM at_shef_decode a
                  LEFT JOIN at_data_stream_id c
                     USING (data_stream_code)
                  JOIN at_cwms_ts_id b
                     USING (ts_code)
                  JOIN at_cwms_ts_spec h
                     USING (ts_code)
                  LEFT JOIN at_loc_group_assignment d
                     ON (    a.location_code = d.location_code
                         AND a.loc_group_code = d.loc_group_code)
                  LEFT JOIN at_loc_group e
                     ON (e.loc_group_code = a.loc_group_code)
                  JOIN at_loc_category f
                     USING (loc_category_code)
                  JOIN cwms_shef_time_zone g
                     USING (shef_time_zone_code)
                  JOIN cwms_unit i
                     ON (a.shef_unit_code = i.unit_code)) a
          LEFT JOIN at_data_feed_id j
             USING (data_feed_code)
          LEFT JOIN cwms_office k
             ON (k.office_code = a.db_office_code)
          LEFT JOIN cwms_office l
             ON (l.office_code = j.db_office_code)
   UNION
   SELECT NULL ts_code,
          NULL cwms_ts_id,
          CASE
             WHEN data_feed_code IS NULL THEN c.office_id
             ELSE a.feed_db_office_id
          END
             db_office_id,
          b.data_stream_id,
          c.office_id stream_db_office_id,
          a.data_feed_id,
          a.feed_db_office_id,
          a.data_feed_prefix,
          NULL loc_group_id,
          NULL loc_category_id,
          NULL loc_alias_id,
          a.shef_loc_id,
          a.shef_pe_code,
          a.shef_tse_code,
          NULL shef_duration_code,
          a.shef_duration_numeric,
          NULL shef_time_zone_id,
          NULL dl_time,
          NULL unit_id,
          NULL unit_system,
          NULL interval_utc_offset,
          NULL interval_forward,
          NULL interval_backward,
          NULL ts_active_flag,
          NULL net_ts_active_flag,
          'T' ignore_shef_spec,
          a.shef_spec,
          NULL location_id,
          NULL parameter_id,
          NULL parameter_type_id,
          NULL interval_id,
          NULL duration_id,
          NULL version_id,
          data_stream_code,
          a.shef_crit_line
     FROM (SELECT data_stream_code,
                  NULL data_feed_code,
                  NULL data_feed_id,
                  NULL data_feed_prefix,
                  NULL feed_db_office_id,
                  shef_loc_id,
                  shef_pe_code,
                  shef_tse_code,
                  shef_duration_numeric,
                     shef_loc_id
                  || '.'
                  || shef_pe_code
                  || '.'
                  || shef_tse_code
                  || '.'
                  || shef_duration_numeric
                     shef_spec,
                     '//'
                  || shef_loc_id
                  || '.'
                  || shef_pe_code
                  || '.'
                  || shef_tse_code
                  || '.'
                  || shef_duration_numeric
                     shef_crit_line
             FROM at_shef_ignore
            WHERE data_feed_code IS NULL
           UNION
           SELECT b.data_stream_code,
                  data_feed_code,
                  b.data_feed_id,
                  TRIM (b.data_feed_prefix) data_feed_prefix,
                  c.office_id feed_db_office_id,
                  shef_loc_id,
                  shef_pe_code,
                  shef_tse_code,
                  shef_duration_numeric,
                     shef_loc_id
                  || '.'
                  || shef_pe_code
                  || '.'
                  || shef_tse_code
                  || '.'
                  || shef_duration_numeric
                     shef_spec,
                     '//'
                  || TRIM (b.data_feed_prefix)
                  || a.shef_loc_id
                  || '.'
                  || a.shef_pe_code
                  || '.'
                  || a.shef_tse_code
                  || '.'
                  || a.shef_duration_numeric
                     shef_crit_line
             FROM at_shef_ignore a
                  LEFT JOIN at_data_feed_id b
                     USING (data_feed_code)
                  JOIN cwms_office c
                     ON B.DB_OFFICE_CODE = c.office_code
            WHERE b.data_stream_code IS NOT NULL) a
          JOIN at_data_stream_id b
             USING (data_stream_code)
          JOIN cwms_office c
             ON B.DB_OFFICE_CODE = c.office_code
/