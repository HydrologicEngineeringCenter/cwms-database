/* Formatted on 8/12/2011 2:37:38 PM (QP5 v5.163.1008.3004) */
--
-- AV_DATA_STREAMS_CURRENT  (View)
--
--  Dependencies:
--   ZV_CURRENT_CRIT_FILE_CODE (View)
--   AV_SHEF_DECODE_SPEC (View)
--   AT_DATA_STREAM_ID (Table)
--   CWMS_OFFICE (Table)
--   CWMS_UTIL (Package)
--   AT_SHEF_CRIT_FILE (Table)
--   AT_SHEF_CRIT_FILE_REC (Table)
--
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_STREAMS_CURRENT', null,
'
/**
 * Displays info about CWMS data streams
 *
 * @since CWMS 2.1
 *
 * @field db_office_id              [description needed]
 * @field data_stream_id            [description needed]
 * @field data_stream_desc          [description needed]
 * @field ds_active_flag            [description needed]
 * @field use_db_shef_spec_mapping  [description needed]
 * @field num_crit_files            [description needed]
 * @field crit_file_exists          [description needed]
 * @field crit_file_creation_date   [description needed]
 * @field crit_file_state           [description needed]
 * @field num_decode_process_recs   [description needed]
 * @field num_decode_ignore_recs    [description needed]
 * @field num_spec_only_ignore_recs [description needed]
 * @field total_ignore_recs         [description needed]
 * @field total_crit_file_recs      [description needed]
 * @field crit_file_code            [description needed]
 * @field data_stream_code          [description needed]
 * @field db_office_code            [description needed]
 */
');

CREATE OR REPLACE FORCE VIEW av_data_streams_current
(
    db_office_id,
    data_stream_id,
    data_stream_desc,
    ds_active_flag,
    use_db_shef_spec_mapping,
    num_crit_files,
    crit_file_exists,
    crit_file_creation_date,
    crit_file_state,
    num_decode_process_recs,
    num_decode_ignore_recs,
    num_spec_only_ignore_recs,
    total_ignore_recs,
    total_crit_file_recs,
    crit_file_code,
    data_stream_code,
    db_office_code
)
AS
    SELECT      office_id db_office_id, data_stream_id, data_stream_desc,
                  active_flag ds_active_flag, use_db_shef_spec_mapping,
                  NVL (num_crit_files, 0) num_crit_files,
                  CASE WHEN crit_file_creation_date IS NULL THEN 'F' ELSE 'T' END crit_file_exists,
                  crit_file_creation_date,
                  CASE WHEN NVL (num_crit_files, 0) = 0 THEN 'STALE' ELSE CASE WHEN NVL (num_mismatched_recs, 0) = 0 THEN 'CURRENT' ELSE 'STALE' END END crit_file_state,
                  NVL (num_decode_process_recs, 0) num_decode_process_recs,
                  NVL (num_decode_ignore_recs, 0) num_decode_ignore_recs,
                  NVL (num_ignore_recs, 0) num_spec_only_ignore_recs,
                  NVL (num_decode_ignore_recs, 0) + NVL (num_ignore_recs, 0) total_ignore_recs,
                  NVL (num_decode_process_recs, 0) + NVL (num_decode_ignore_recs, 0) + NVL (num_ignore_recs, 0) total_crit_file_recs,
                  crit_file_code, data_stream_code, db_office_code
         FROM   at_data_stream_id a
                  LEFT JOIN (SELECT        data_stream_code,
                                                COUNT (*) num_mismatched_recs
                                      FROM    ( (SELECT    data_stream_code,
                                                                b.shef_crit_line
                                                      FROM        (SELECT     crit_file_code,
                                                                                 data_stream_code
                                                                        FROM     zv_current_crit_file_code) a
                                                                JOIN
                                                                    at_shef_crit_file b
                                                                USING (crit_file_code)
                                                    MINUS
                                                    SELECT    data_stream_code,
                                                                a.shef_crit_line
                                                      FROM    av_shef_decode_spec a
                                                     WHERE    data_stream_code IS NOT NULL)
                                                 UNION
                                                 (SELECT   data_stream_code, a.shef_crit_line
                                                     FROM   av_shef_decode_spec a
                                                    WHERE   data_stream_code IS NOT NULL
                                                  MINUS
                                                  SELECT   data_stream_code, b.shef_crit_line
                                                     FROM       (SELECT    crit_file_code,
                                                                                data_stream_code
                                                                      FROM    zv_current_crit_file_code) a
                                                              JOIN
                                                                  at_shef_crit_file b
                                                              USING (crit_file_code)))
                                 GROUP BY    data_stream_code) b
                      USING (data_stream_code)
                  LEFT JOIN (SELECT        data_stream_code, COUNT (*) num_crit_files
                                      FROM    at_shef_crit_file_rec
                                 GROUP BY    data_stream_code) c
                      USING (data_stream_code)
                  JOIN cwms_office d
                      ON (a.db_office_code = d.office_code)
                  LEFT JOIN zv_current_crit_file_code e
                      USING (data_stream_code)
        WHERE   delete_date IS NULL
    ORDER BY   db_office_id, UPPER (data_stream_id)
/
