/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @field crit_file_code          [description needed]
 * @field data_stream_code        [description needed]
 * @field crit_file_creation_date [description needed]
 * @field num_decode_process_recs [description needed]
 * @field num_decode_ignore_recs  [description needed]
 * @field num_ignore_recs         [description needed]
 * @field num_crit_files          [description needed]
 * @field crit_file_hash          [description needed]
 */
CREATE OR REPLACE FORCE VIEW zv_current_crit_file_code
(
    crit_file_code,
    data_stream_code,
    crit_file_creation_date,
    num_decode_process_recs,
    num_decode_ignore_recs,
    num_ignore_recs,
    num_crit_files,
    crit_file_hash
)
AS
    SELECT    crit_file_code, data_stream_code, crit_file_creation_date,
                a.num_decode_process_recs, a.num_decode_ignore_recs,
                a.num_ignore_recs, num_crit_files, crit_file_hash
      FROM        at_shef_crit_file_rec a
                JOIN
                    (SELECT        data_stream_code, COUNT (*) num_crit_files,
                                    MAX (a.crit_file_creation_date) crit_file_creation_date
                          FROM    at_shef_crit_file_rec a
                     GROUP BY    data_stream_code) b
                USING (data_stream_code, crit_file_creation_date)

/
